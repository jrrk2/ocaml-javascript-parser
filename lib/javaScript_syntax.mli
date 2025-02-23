open Prelude

type prefixOp =
  | PrefixLNot 
  | PrefixBNot 
  | PrefixPlus
  | PrefixMinus 
  | PrefixTypeof 
  | PrefixVoid 
  | PrefixDelete

type unaryAssignOp =
  | PrefixInc 
  | PrefixDec 
  | PostfixInc 
  | PostfixDec

type infixOp =
  | OpLT 
  | OpLEq 
  | OpGT 
  | OpGEq  
  | OpIn
  | OpInstanceof
  | OpEq
  | OpNEq
  | OpStrictEq
  | OpStrictNEq
  | OpLAnd
  | OpLOr 
  | OpMul
  | OpDiv
  | OpMod
  | OpSub
  | OpLShift
  | OpSpRShift
  | OpZfRShift
  | OpBAnd
  | OpBXor
  | OpBOr
  | OpAdd

type assignOp =
  | OpAssign
  | OpAssignAdd
  | OpAssignSub
  | OpAssignMul
  | OpAssignDiv
  | OpAssignMod
  | OpAssignLShift
  | OpAssignSpRShift
  | OpAssignZfRShift
  | OpAssignBAnd
  | OpAssignBXor
  | OpAssignBOr

type const =
  | CString of string
  | CRegexp of string * bool * bool
  | CNum of float
  | CInt of int
  | CBool of bool
  | CNull 
  | CUndefined

type prop =
  | PropId of id
  | PropString of string
  | PropNum of int

type varDecl =
  | VarDeclNoInit of Pos.t * id
  | VarDecl of Pos.t * id * expr
  | ArrayPattern of Pos.t * id list

and forInit =
  | NoForInit
  | VarForInit of varDecl list
  | ExprForInit of expr

and catch =
  | CatchClause of Pos.t * id * stmt

and forInInit =
  | VarForInInit of Pos.t * id
  | NoVarForInInit of Pos.t * id

and forOfInit =
  | VarForOfInit of Pos.t * id
  | NoVarForOfInit of Pos.t * id

and caseClause =
  | CaseClause of Pos.t * expr * stmt
  | CaseDefault of Pos.t * stmt

and lvalue =
  | VarLValue of Pos.t * id
  | DotLValue of Pos.t * expr * id
  | BracketLValue of Pos.t * expr * expr
  | MemberLValue of Pos.t * expr * expr

and expr =
  | ConstExpr of Pos.t * const
  | ArrayExpr of Pos.t * expr list
  | ObjectExpr of Pos.t * (Pos.t * prop * expr) list
  | ThisExpr of Pos.t
  | VarExpr of Pos.t * id
  | DotExpr of Pos.t * expr * id
  | BracketExpr of Pos.t * expr * expr
  | NewExpr of Pos.t * expr * expr list
  | PrefixExpr of Pos.t * prefixOp * expr
  | UnaryAssignExpr of Pos.t * unaryAssignOp * lvalue
  | InfixExpr of Pos.t * infixOp * expr * expr
  | IfExpr of Pos.t * expr * expr * expr
  | AssignExpr of Pos.t * assignOp * lvalue * expr
  | ParenExpr of Pos.t * expr
  | ListExpr of Pos.t * expr * expr
  | CallExpr of Pos.t * expr * expr list
  | FuncExpr of Pos.t * id list * stmt
  | NamedFuncExpr of Pos.t * id * id list * stmt
  | SeqExpr of Pos.t * expr list
  | MemberExpr of Pos.t * expr * expr
  | ArrowFuncExpr of Pos.t * id list * stmt
  | TemplateExpr of Pos.t * expr list * expr list
  | TemplateElem of Pos.t * (string*string) list
  | ClassExpr of Pos.t * id * id * stmt
  
and stmt =
  | BlockStmt of Pos.t * stmt list
  | EmptyStmt of Pos.t  
  | ExprStmt of expr
  | IfStmt of Pos.t * expr * stmt * stmt
  | IfSingleStmt of Pos.t * expr * stmt
  | SwitchStmt of Pos.t * expr * caseClause list
  | WhileStmt of Pos.t * expr * stmt
  | DoWhileStmt of Pos.t * stmt * expr
  | BreakStmt of Pos.t
  | BreakToStmt of Pos.t * id
  | ContinueStmt of Pos.t
  | ContinueToStmt of Pos.t * id
  | LabelledStmt of Pos.t * id * stmt
  | ForInStmt of Pos.t * forInInit * expr * stmt
  | ForOfStmt of Pos.t * forOfInit * expr * stmt
  | ForStmt of Pos.t * forInit * expr * expr * stmt
  | TryStmt of Pos.t * stmt * catch list * stmt
  | ThrowStmt of Pos.t * expr
  | ReturnStmt of Pos.t * expr
  | WithStmt of Pos.t * expr * stmt
  | VarDeclStmt of Pos.t * varDecl list
  | FuncStmt of Pos.t * id * id list * stmt
  | ClassDeclStmt of Pos.t * id * id * stmt
  | ClassBodyStmt of Pos.t * stmt list
  | MethodDefinitionStmt of Pos.t * bool * bool * expr * string * expr
  
val pos_stmt : stmt -> Pos.t
val pos_expr : expr -> Pos.t

type prog =
  | Prog of Pos.t * stmt list
