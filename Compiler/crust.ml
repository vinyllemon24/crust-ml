
(* This is the main file of the crust compiler *)
open Format
open Lexing

(* Opção de compilação, para parar na fase de parsing *)
let parse_only = ref false
let type_only = ref false
let no_asm = ref false
let print_ast = ref false
let print_tast = ref false
let print_past = ref false

(* Nome dos ficheiros fonte e alvo *)
let ifile = ref ""
let ofile = ref ""

let set_file f s = f := s

(* As opções do compilador que são mostradas quando é invocada o comando --help *)
let options =
  ["--parse-only", Arg.Set parse_only,
   "  Executes only the lexer and parser ";
   "--type-only", Arg.Set type_only,
   "  Executes only the typing ";
   "--no-asm", Arg.Set no_asm,
   "  Executes until ownership ";
   "--print-ast", Arg.Set print_ast,
   "  Prints the AST of a givin file ";
   "--print-tast", Arg.Set print_tast,
   "  Prints the TAST of a givin file ";
   "--print-past", Arg.Set print_past,
   "  Prints the PAST of a givin print_past ";
   "-o", Arg.String (set_file ofile),
   "<file>  To indicate the name of the output file"]

let usage = "usage: crust [option(s)] file.rs"

(* localiza um erro indicando a linha e a coluna *)
let localisation pos =
  let l = pos.pos_lnum in
  let c = pos.pos_cnum - pos.pos_bol + 1 in
  eprintf "\n\nFile \"%s\", line %d, characters %d-%d:\n" !ifile l (c-1) c

let () =
  (* Parsing da linha de comando *)
  Arg.parse options (set_file ifile) usage;

  (* Verifica-se que o nome do ficheiro fonte foi bem introduzido *)
  if !ifile="" then begin eprintf "\n\nerror:\n\n    Was expecting a file but got none. Pass the file to compile\n\n@?"; exit 1 end;

  (* Verifies if the given file has a .rs extension *)
  if not (Filename.check_suffix !ifile ".rs") then begin
    eprintf "The input file must be of the type .rs\n@?";
    Arg.usage options usage;
    exit 1
  end;

   (* Por omissão, o ficheiro alvo tem o mesmo nome que o ficheiro fonte,
     só muda a extensão *)
  if !ofile="" then ofile := Filename.chop_suffix !ifile ".rs" ^ ".s";

  (* Abertura do ficheiro fonte em leitura *)
  let f = open_in !ifile in

  (* Criação do buffer de análise léxica *)
  let buf = Lexing.from_channel f in

  try
    (* Parsing: A função Parser.prog transforma o buffer d'análise léxica
       numa árvore de sintaxe abstracta se nenujk erro  (léxico ou sintáctico)
       foi detectado.
       A função Lexer.token é utilizada por Parser.prog para obter
       o próximo token. *)
    let p = Parser.prog Lexer.next_token buf in
    close_in f;

    (* Stop here aqui se só queremos o parsing *)
    if !parse_only then exit 0;
    if !print_ast || !print_tast || !print_past then Printer.print_file p;
    
    (* Type AST *)
    let p = Typing.type_file p in
    if !print_tast then Printer_tast.print_file p;
    if !type_only then exit 0;
    
    (* Ownership *)
    let _ = Ownership.verify_ownership p in
    if !no_asm then exit 0;

    let p = Pre_compile.pcompile_file p in
    if !print_past then Printer_past.print_file p;
    Compile.compile_program p !ofile

  with
  | Lexer.Lexing_error c ->
    (* Erro léxico. Recupera-se a posição absoluta e converte-se para número de linha *)
    localisation (Lexing.lexeme_start_p buf);
	  eprintf "\nerror:\n\n  Lexical error: invalid symbol: %s.\n\n@." c;
    exit 1
  | Lexer.Lexing_error_comment c ->
    localisation (Lexing.lexeme_start_p buf);
	  eprintf "\nerror:\n\n  Lexical error:\n  %s.\n\n@." c;
    exit 1
  | Parser.Error ->
	  (* Erro sintáctio. Recupera-se a posição e converte-se para número de linha *)
	  localisation (Lexing.lexeme_start_p buf);
	  eprintf "\nerror:\n\n  Syntatic error: invalid derivation.\n\n@.";
    exit 1
  | Typing.Error (s, line)-> 
    eprintf "\n\nFile \"%s\", line %d:\n" !ifile line;
    eprintf "\nerror:\n\n  Typing analysis:\n  %s\n@." s;
    exit 1
  | Ownership.Error s -> 
    eprintf "\n\nFile \"%s\n" !ifile;
    eprintf "\nerror:\n\n  Ownership error:\n  %s\n@." s;
    exit 1
