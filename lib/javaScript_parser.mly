%{
(** A JavaScript parser that does not do semicolon insertion. *)
open Prelude
open JavaScript_syntax

exception Expected_lvalue

exception Parse_failure of string

let rec expr_to_lvalue (e : expr) : lvalue =  match e with
  | VarExpr (p,x) -> VarLValue (p,x)
  | DotExpr (p,e,x) -> DotLValue (p,e,x)
  | BracketExpr (p,e1,e2) -> BracketLValue (p,e1,e2)
  | ParenExpr (_, e) -> expr_to_lvalue e
  | _ -> raise Expected_lvalue
%}

%token <string> ContinueId
%token <string> BreakId
%token <string> Id
%token <string> String
%token <string * bool * bool> Regexp
%token <int> Int
%token <float> Float
%token <JavaScript_syntax.assignOp> AssignOp

%token If Else True False New Instanceof This Null Function Typeof Void
 Delete Switch Default Case While Do Break Var In Of For Try Catch Finally Throw
 Return With Continue

%token LBrace RBrace LParen RParen Assign
 Semi Comma Ques Colon LOr LAnd BOr BXor BAnd StrictEq AbstractEq
 StrictNEq AbstractNEq LShift RShift SpRShift LEq LT GEq GT PlusPlus MinusMinus
 Plus Minus Times Div Mod Exclamation Tilde Period LBrack RBrack Arrow Unit

%token EOF

(* http://stackoverflow.com/questions/1737460/
   how-to-find-shift-reduce-conflict-in-this-yacc-file *)
%nonassoc GreaterThanColon
%nonassoc Colon
%nonassoc LowerThanElse
%nonassoc Else

%left LOr
%left LAnd
%left BOr
%left BXor
%left BAnd
%left StrictEq StrictNEq AbstractEq AbstractNEq
%left LT LEq GT GEq In Of Instanceof
%left LShift RShift SpRShift
%left Plus Minus
%left Times Div Mod


%start program
%start expression

%type <JavaScript_syntax.prog> program
%type <JavaScript_syntax.expr> expression

%%

exprs
  : { [] }
  | assign_expr { [$1] }
  | assign_expr Comma exprs { $1::$3 }

stmts
  : stmt { [$1] }
  | stmt Semi { [$1] }
  | stmt Semi stmts { $1 :: $3 }

cases
  : { [] }
  | case cases { $1 :: $2 }

catches
  : { [] }
  | catch catches { $1 :: $2 }

ids
  : { [] }
  | Unit { [] }
  | Id { [$1] }
  | Id Comma ids { $1 :: $3 }

prop
  : Id { PropId $1 }  %prec GreaterThanColon
  | String { PropString $1 }
  | Int { PropString (string_of_int $1) }
  | Default { PropString "default" }
  | True { PropString "true" }

fields
  : { [] }
  | prop Colon expr 
    { [ (Pos.real ($startpos($1), $startpos($3)), $1, $3) ] }
  | prop Colon expr Comma fields  
      { (Pos.real ($startpos($1), $startpos($3)), $1, $3) :: $5 }

varDecls
  : varDecl { [$1] }
  | varDecl Comma varDecls { $1::$3 }

varDecls_noin
  : varDecl_noin { [$1] }
  | varDecl_noin Comma varDecls_noin { $1::$3 } 

element_list
  : 
      { [] }
  | Comma 
      { [ ConstExpr (Pos.real ($startpos, $endpos), CUndefined) ] }
  | assign_expr { [$1] }
  | assign_expr Comma element_list 
      { $1::$3 }

const :
  | True { CBool true }
  | False { CBool false }
  | Null { CNull }
  | String { CString $1 }
  | Regexp { let re, g, ci = $1 in  CRegexp (re, g, ci) }
  | Int { CInt $1}
  | Float { CNum $1 }

primary_expr :
  | const { ConstExpr (Pos.real ($startpos, $endpos), $1) }
  | Id { VarExpr (Pos.real ($startpos, $endpos), $1) }
  | LBrack element_list RBrack
      { ArrayExpr (Pos.real ($startpos, $endpos),$2) }
  | LBrace fields RBrace
      { ObjectExpr (Pos.real ($startpos, $endpos),$2) }
  | LBrace fields Semi RBrace
      { ObjectExpr (Pos.real ($startpos, $endpos),$2) }
  | LParen expr RParen
      { ParenExpr (Pos.real ($startpos, $endpos),$2) }
  | This { ThisExpr (Pos.real ($startpos, $endpos)) }

member_expr
  : primary_expr 
      { $1 }
  | Function Unit body=src_elt_block
    { FuncExpr (Pos.real ($startpos, $endpos), [], body) }
  | Function LParen ids RParen body=src_elt_block
    { FuncExpr (Pos.real ($startpos, $endpos), $3, body) }
  | Function Id Unit body=src_elt_block
    { NamedFuncExpr (Pos.real ($startpos, $endpos), $2, [], body) }
  | Function Id LParen ids RParen body=src_elt_block
    { NamedFuncExpr (Pos.real ($startpos, $endpos), $2, $4, body) } 
  | Unit Arrow body=src_elt_block
    { FuncExpr (Pos.real ($startpos, $endpos), [], body) }
  | LParen ids RParen Arrow LParen Function Unit body=stmt RParen
    { FuncExpr (Pos.real ($startpos, $endpos), $2, body) }
  | member_expr Period Id
      { DotExpr (Pos.real ($startpos, $endpos), $1, $3) } 
  | member_expr Period Return
      { DotExpr (Pos.real ($startpos, $endpos), $1, "return") } 
  | member_expr Period Default
      { DotExpr (Pos.real ($startpos, $endpos), $1, "default") } 
  | member_expr LBrack expr RBrack
      { BracketExpr (Pos.real ($startpos, $endpos),$1,$3) }
  | New member_expr LParen exprs RParen 
      { NewExpr (Pos.real ($startpos, $endpos),$2,$4) }
  
new_expr
  : member_expr
      { $1 }
  | New new_expr
      { NewExpr (Pos.real ($startpos, $endpos),$2,[]) }


call_expr
  : member_expr LParen exprs RParen
      { CallExpr (Pos.real ($startpos, $endpos),$1,$3) }
  | member_expr Unit
      { CallExpr (Pos.real ($startpos, $endpos),$1,[]) }
  | call_expr Unit
      { CallExpr (Pos.real ($startpos, $endpos),$1,[]) }
  | call_expr LParen exprs RParen
      { CallExpr (Pos.real ($startpos, $endpos),$1,$3) }
  | call_expr LBrack expr RBrack 
      { BracketExpr (Pos.real ($startpos, $endpos),$1,$3) }
  | call_expr Period Id 
      { DotExpr (Pos.real ($startpos, $endpos), $1, $3) }

lhs_expr
  : new_expr
      { $1 }
  | call_expr 
      { $1 }

postfix_expr
  : lhs_expr 
      { $1 }
  | lhs_expr PlusPlus
      { UnaryAssignExpr (Pos.real ($startpos, $endpos),PostfixInc,expr_to_lvalue $1) }
  | lhs_expr MinusMinus
      { UnaryAssignExpr (Pos.real ($startpos, $endpos),PostfixDec,expr_to_lvalue $1) }

unary_expr
  : postfix_expr 
      { $1 }
  | PlusPlus unary_expr 
      { UnaryAssignExpr (Pos.real ($startpos, $endpos),PrefixInc,expr_to_lvalue $2) }
  | MinusMinus unary_expr 
      { UnaryAssignExpr (Pos.real ($startpos, $endpos),PrefixDec,expr_to_lvalue $2) }
  | Exclamation unary_expr 
      { PrefixExpr (Pos.real ($startpos, $endpos),PrefixLNot,$2) } 
  | Tilde unary_expr 
      { PrefixExpr (Pos.real ($startpos, $endpos),PrefixBNot,$2) }
  | Minus unary_expr
      { PrefixExpr (Pos.real ($startpos, $endpos),PrefixMinus,$2) }
  | Plus unary_expr
      { PrefixExpr (Pos.real ($startpos, $endpos),PrefixPlus,$2) }
  | Typeof unary_expr
      { PrefixExpr (Pos.real ($startpos, $endpos),PrefixTypeof,$2) }
  | Void unary_expr
      { PrefixExpr (Pos.real ($startpos, $endpos),PrefixVoid,$2) }
  | Delete unary_expr 
      { PrefixExpr (Pos.real ($startpos, $endpos),PrefixDelete,$2) }

(* Combines UnaryExpression, MultiplicativeExpression, AdditiveExpression, and
   ShiftExpression by using precedence and associativity rules. *)
op_expr
  : unary_expr { $1 }
  | op_expr Times op_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpMul,$1,$3) }
  | op_expr Div op_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpDiv,$1,$3) }
  | op_expr Mod op_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpMod,$1,$3) }
  | op_expr Plus op_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpAdd,$1,$3) }
  | op_expr Minus op_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpSub,$1,$3) }
  | op_expr LShift op_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpLShift,$1,$3) }
  | op_expr RShift op_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpZfRShift,$1,$3) }
  | op_expr SpRShift op_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpSpRShift,$1,$3) }

in_expr
  : op_expr 
      { $1 }
  | in_expr LT in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpLT,$1,$3) }
  | in_expr GT in_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpGT,$1,$3) }
  | in_expr LEq in_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpLEq,$1,$3) }
  | in_expr GEq in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpGEq,$1,$3) }
  | in_expr Instanceof in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpInstanceof,$1,$3) }
  | in_expr In in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpIn,$1,$3) }
  | in_expr StrictEq in_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpStrictEq,$1,$3) }
  | in_expr StrictNEq in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpStrictNEq,$1,$3) }
  | in_expr AbstractEq in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpEq,$1,$3) }
  | in_expr AbstractNEq in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpNEq,$1,$3) }
  | in_expr BAnd in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpBAnd,$1,$3) }
  | in_expr BXor in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpBXor,$1,$3) }
  | in_expr BOr in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpBOr,$1,$3) }
  | in_expr LAnd in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpLAnd,$1,$3) }
  | in_expr LOr in_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpLOr,$1,$3) }

cond_expr
  : in_expr
      { $1 }
  | in_expr Ques assign_expr Colon assign_expr 
      { IfExpr (Pos.real ($startpos, $endpos),$1,$3,$5) }


assign_expr
  : cond_expr
      { $1 }
  (* we need the use Assign (token for =) in other productions. *)
  | lhs_expr AssignOp assign_expr 
    { AssignExpr (Pos.real ($startpos, $endpos), $2, expr_to_lvalue $1, $3) }
  | lhs_expr Assign assign_expr 
    { AssignExpr (Pos.real ($startpos, $endpos), OpAssign, expr_to_lvalue $1, $3) }


expr 
  : assign_expr 
      { $1 }
  | expr Comma assign_expr
      { ListExpr (Pos.real ($startpos, $endpos),$1,$3) }

noin_expr
  : op_expr
      { $1 }
  | noin_expr LT noin_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpLT,$1,$3) }
  | noin_expr GT noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpGT,$1,$3) }
  | noin_expr LEq noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpLEq,$1,$3) }
  | noin_expr GEq noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpGEq,$1,$3) }
  | noin_expr Instanceof noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpInstanceof,$1,$3) }
  | noin_expr StrictEq noin_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpStrictEq,$1,$3) }
  | noin_expr StrictNEq noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpStrictNEq,$1,$3) }
  | noin_expr AbstractEq noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpEq,$1,$3) }
  | noin_expr AbstractNEq noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpNEq,$1,$3) }
  | noin_expr BAnd noin_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpBAnd,$1,$3) }
  | noin_expr BXor noin_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpBXor,$1,$3) }
  | noin_expr BOr noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpBOr,$1,$3) }
  | noin_expr LAnd noin_expr
      { InfixExpr (Pos.real ($startpos, $endpos),OpLAnd,$1,$3) }
  | noin_expr LOr noin_expr 
      { InfixExpr (Pos.real ($startpos, $endpos),OpLOr,$1,$3) }

cond_noin_expr
  : noin_expr { $1 }
  | noin_expr Ques assign_noin_expr Colon assign_noin_expr 
    { IfExpr (Pos.real ($startpos, $endpos),$1,$3,$5) }

assign_noin_expr
  : cond_noin_expr { $1 }
  | lhs_expr AssignOp assign_noin_expr 
    { AssignExpr (Pos.real ($startpos, $endpos), $2, expr_to_lvalue $1, $3) }
  | lhs_expr Assign assign_noin_expr 
    { AssignExpr (Pos.real ($startpos, $endpos), OpAssign, expr_to_lvalue $1, $3) }

expr_noin
  : assign_noin_expr { $1 }
  | noin_expr Comma assign_noin_expr 
      { ListExpr (Pos.real ($startpos, $endpos),$1,$3) }

varDecl
  : Id { VarDeclNoInit (Pos.real ($startpos, $endpos),$1) }
  | Id Assign assign_expr { VarDecl (Pos.real ($startpos, $endpos),$1,$3) }

varDecl_noin
  : Id { VarDeclNoInit (Pos.real ($startpos, $endpos),$1) }
  | Id Assign assign_noin_expr { VarDecl (Pos.real ($startpos, $endpos),$1,$3) }

case
  : Case expr Colon stmts 
  { CaseClause (Pos.real ($startpos, $endpos),$2,BlockStmt (Pos.real ($startpos, $endpos),$4)) }
  | Default Colon stmts
  { CaseDefault (Pos.real ($startpos, $endpos),BlockStmt (Pos.real ($startpos, $endpos),$3)) }

forInInit :
  | Id 
      { NoVarForInInit (Pos.real ($startpos, $endpos), $1) }
  | Var Id 
      { VarForInInit (Pos.real ($startpos, $endpos), $2) }

forOfInit :
  | Id 
      { NoVarForOfInit (Pos.real ($startpos, $endpos), $1) }
  | Var Id 
      { VarForOfInit (Pos.real ($startpos, $endpos), $2) }

forInit
  : { NoForInit }
  | Var varDecls_noin { VarForInit $2 }
  | expr_noin { ExprForInit $1 }

catch
  : Catch LParen Id RParen block
    { CatchClause (Pos.real ($startpos, $endpos), $3, $5) }


block : LBrace stmts RBrace
      { BlockStmt (Pos.real ($startpos, $endpos),$2) }

paren_expr : LParen expr RParen
      { ParenExpr (Pos.real ($startpos, $endpos),$2) }

opt_expr :
  | { ConstExpr (Pos.real ($startpos, $endpos), CUndefined) }
  | expr { $1 }

stmt
  : Semi { EmptyStmt (Pos.real ($startpos, $endpos)) }
  | LBrace stmts RBrace
      { BlockStmt (Pos.real ($startpos, $endpos), $2) }
  | expr
      { match $1 with
          | NamedFuncExpr (p, x, args, body) -> FuncStmt (p, x, args, body)
          | e -> ExprStmt e 
      }
  | Continue
      { ContinueStmt (Pos.real ($startpos, $endpos)) }
  | ContinueId
      { ContinueToStmt (Pos.real ($startpos, $endpos),$1) }
  | If LParen expr  RParen stmt  %prec LowerThanElse
    { IfSingleStmt (Pos.real ($startpos, $endpos), $3, $5) }
  | If LParen expr RParen stmt Else stmt
    { IfStmt (Pos.real ($startpos, $endpos), $3, $5, $7) }

  | Switch paren_expr LBrace cases RBrace 
      { SwitchStmt (Pos.real ($startpos, $endpos),$2,$4) }
  | While paren_expr stmt
      { WhileStmt (Pos.real ($startpos, $endpos),$2,$3) }
  | Do block While paren_expr
      { DoWhileStmt (Pos.real ($startpos, $endpos),$2,$4) }
  | Break
      { BreakStmt (Pos.real ($startpos, $endpos)) }
  | BreakId
      { BreakToStmt (Pos.real ($startpos, $endpos),$1) }
  | Id Colon stmt { LabelledStmt (Pos.real ($startpos, $endpos), $1, $3) }
  | For LParen forInInit In expr RParen stmt
    { ForInStmt (Pos.real ($startpos, $endpos),$3,$5,$7) }
  | For LParen forOfInit Of expr RParen stmt
    { ForOfStmt (Pos.real ($startpos, $endpos),$3,$5,$7) }
  | For LParen forInit Semi opt_expr Semi opt_expr RParen stmt
    { ForStmt (Pos.real ($startpos, $endpos),$3,$5,$7,$9) }
  | Try block catches
    { TryStmt (Pos.real ($startpos, $endpos),$2,$3,EmptyStmt (Pos.real ($startpos, $endpos))) }
  | Try block catches Finally block { TryStmt (Pos.real ($startpos, $endpos),$2,$3,$5) }
  | Throw expr
      { ThrowStmt (Pos.real ($startpos, $endpos),$2) }
  | Return
      { ReturnStmt (Pos.real ($startpos, $endpos),
                    ConstExpr (Pos.real ($startpos, $endpos), CUndefined)) }
  | Return expr
      { ReturnStmt (Pos.real ($startpos, $endpos),$2) } 
  | Var varDecls
      { VarDeclStmt (Pos.real ($startpos, $endpos),$2) }
  | With LParen expr RParen stmt
      { WithStmt (Pos.real ($startpos, $endpos), $3, $5) }

src_elt_block
  : LBrace src_elts RBrace 
      { BlockStmt (Pos.real ($startpos, $endpos),$2) }
  | LBrace RBrace 
      { BlockStmt (Pos.real ($startpos, $endpos), []) }
 
src_elts
  : src_elt { [$1] }
(*
  | src_elt Semi { [$1] }
*)
| src_elt Semi src_elts { $1::$3 }
  | src_elt src_elts { $1::$2 }

src_elt
  : stmt { $1 }
(*
*)

program : src_elts EOF { Prog (Pos.real ($startpos, $endpos), $1) }

expression : expr EOF { $1 }

%%
