(*
  Última alteração: 11-12-2020
  Descricao: Type Abstract Syntax Tree
*)

open Stdint

type ident = string

type typed_unop = 
  | TUneg
  | TUnot
  
and typed_binop =
  | TBadd | TBsub | TBmul | TBdiv | TBmod
  | TBeq  | TBneq | TBlt  | TBle  | TBgt | TBge
  | TBand | TBor 
  
and typed_expr =
  | TEcst     of Ast.crust_const *Ast.crust_types
  | TEident   of ident *Ast.crust_types
  | TEbinop   of typed_binop * typed_expr * typed_expr *Ast.crust_types
  | TEunop    of typed_unop * typed_expr *Ast.crust_types
  | TEcall    of ident * typed_expr list *Ast.crust_types
  
and typed_stmt =
  | TSif       of typed_expr * typed_stmt * typed_elif list
  | TSwhile    of typed_expr * typed_stmt * int
  | TSdeclare  of ident *Ast.crust_types * typed_expr
  | TSassign   of ident * typed_expr * int
  | TSprintn   of typed_expr
  | TSprint    of typed_expr
  | TSblock    of typed_stmt list
  | TScontinue
  | TSbreak
  | TSreturn   of typed_expr * int * Ast.crust_types
  | TSnothing
  | TSexpr     of typed_expr

and typed_elif = typed_expr * typed_stmt * int

and typed_global_stmt = 
  | TGSblock    of typed_global_stmt list
  | TGSfunction of ident * pairs list * Ast.crust_types * typed_stmt
  | TGSstruct   of ident * pairs list
 
and pairs = ident * Ast.crust_types

and program = typed_global_stmt
