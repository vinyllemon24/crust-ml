(*
  Última alteração: 28-12-2019
  Descricao: Parser do Natrix
*)

/* Ponto de entrada da gramática */
%start prog

/* Tipo dos valores devolvidos pelo parser */
%type <Ast.program> prog

%%

prog:
| b = list(stmts) EOF { Stblock(b, !Lexer.line_num) }
;

stmts:
| FUN f = ident "(" x = separated_list(",", argument_list) ")" ":"  r = type_def s = function_suite 
              { Stfunction(f, x, r, s, !Lexer.line_num)}
| s = stmt    { Stmt(s, !Lexer.line_num) } 
;

argument_list:
|  id = ident ":" t = type_def {(id, t)}
;

function_suite:
| "{" l = list(stmt) "}"    { Sblock (l, !Lexer.line_num)}
| "="">" e = expr ";"       { Sreturn(e, !Lexer.line_num)}
;


suite:
| l = list(stmt)     { Sblock (l, !Lexer.line_num) }
;

elif:
| ELSE IF "(" e = expr ")" "{" s = suite "}" { (e, s, !Lexer.line_num) }
| ELSE "{" s = suite "}" { ( Ecst(1L, !Lexer.line_num), s, !Lexer.line_num) }
;

stmt:
| s = simple_stmt                                        { s } 
| IF "(" e = expr ")" "{" s1 = suite "}" l = list(elif)  { Sif(e, s1, l, !Lexer.line_num)}
| WHILE "(" e = expr ")" "{" s = suite "}"               { Swhile(e, s, !Lexer.line_num) }
| LOOP "{" s = suite "}"                                 { Sloop(s, !Lexer.line_num)}
| FOR "(" id = ident ":" t = type_def "=" e = expr ";" cond = expr ";" incr = expr ")" "{" s = suite "}" {Sfor(id, t, e, cond, incr, s, !Lexer.line_num)} 
;

simple_stmt:
| RETURN e = expr ";"                              { Sreturn(e, !Lexer.line_num) }
| BREAK ";"                                        { Sbreak !Lexer.line_num }
| CONTINUE ";"                                     { Scontinue !Lexer.line_num }
| LET id = ident ":" t = type_def "=" e = expr ";" { Sdeclare (id, t, e, !Lexer.line_num) }
| id = ident o = binop"=" e = expr ";"             { Sassign (id, Ebinop(o, Eident (id, !Lexer.line_num), e, !Lexer.line_num), !Lexer.line_num) }
| PRINT "(" e = expr ")" ";"                       { Sprint(e, !Lexer.line_num) }
| PRINTN "(" e = expr ")" ";"                      { Sprintn(e, !Lexer.line_num) }
| SCANF "(" id = ident ")" ";"                     { Sscanf(id, !Lexer.line_num) }
| ";"                                              { Snothing(!Lexer.line_num) }
;

type_def:
| INT           { Int }
| id = ident    { CTid id }
;

expr:
| c = CST                           { Ecst (c, !Lexer.line_num) }
| id = ident                        { Eident (id, !Lexer.line_num) }
| u = unop e1 = expr                { Eunop (u, e1, !Lexer.line_num) }
| e1 = expr o = binop e2 = expr     { Ebinop (o, e1, e2, !Lexer.line_num) }
| id = ident "(" l = separated_list("," , expr) ")" { Ecall(id, l, !Lexer.line_num)}
| "(" e = expr ")"                  { e }
;

%inline unop:
| MINUS  { Uneg }
| NOT    { Unot }
| BITNOT { Ubitnot }
;

%inline binop:
| PLUS  { Badd }
| MINUS { Bsub }
| TIMES { Bmul }
| DIV   { Bdiv }
| MOD   { Bmod }
| EQ    { Beq }
| NEQ   { Bneq }
| GT    { Bgt }
| LT    { Blt }
| GET   { Bge }
| LET   { Ble }
| AND   { Band }
| OR    { Bor  }
| BITAND{ Bitand } 
| BITOR { Bitor }
| BITXOR{ Bitxor }
| LSHIFT{ Bitls }
| RSHIFT{ Bitrs }
;

ident:
| id = IDENT { id }
;