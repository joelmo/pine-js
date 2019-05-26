grammar Spine;

tokens { INDENT, DEDENT }

@lexer::members {
let CommonToken = require('antlr4/Token').CommonToken;
let SpineParser = require('./SpineParser').SpineParser;

SpineLexer.prototype.indents = [0];

SpineLexer.prototype.token_queue = [];

SpineLexer.prototype.nextToken = function() {
    let next = antlr4.Lexer.prototype.nextToken.call(this);
    return this.token_queue.length ? this.token_queue.shift() : next;
};

SpineLexer.prototype.pushToken = function(type, text) {
    let stop = this.getCharIndex() - 1;
    let start = text.length ? stop - text.length + 1 : stop;
    let t = CommonToken(this._tokenFactorySourcePair, type, antlr4.Lexer.DEFAULT_TOKEN_CHANNEL, start, stop);
    this.emitToken(t);
    this.token_queue.push(t);
};

SpineLexer.prototype.previous = function() {
    return this.indents[this.indents.length - 1];
};
}

COND : '?' ;
COND_ELSE : ':' ;
OR : 'or' ;
AND : 'and' ;
NOT : 'not' ;
EQ : '==' ;
NEQ : '!=' ;
GT : '>' ;
GE : '>=' ;
LT : '<' ;
LE : '<=' ;
PLUS : '+' ;
MINUS : '-' ;
MUL : '*' ;
DIV : '/' ;
MOD : '%' ;
COMMA : ',';
ARROW : '=>' ;
LPAR : '(' ;
RPAR : ')' ;
LSQBR : '[' ;
RSQBR : ']' ;
DEFINE : '=';
IF_COND : 'if' ;
IF_COND_ELSE : 'else' ;
ASSIGN : ':=' ;
FOR_STMT : 'for' ;
FOR_STMT_TO : 'to' ;
FOR_STMT_BY : 'by' ;
BREAK : 'break' ;
CONTINUE : 'continue' ;
INT_LITERAL : DIGITS ;
FLOAT_LITERAL : ( '.' DIGITS ( EXP )? | DIGITS ( '.' ( DIGITS ( EXP )? )? | EXP ) );
STR_LITERAL : ( '"' ( ESC | ~ ( '\\' | '\n' | '"' ) )* '"' | '\'' ( ESC | ~ ( '\\' | '\n' | '\'' ) )* '\'' );
BOOL_LITERAL : ( 'true' | 'false' );
COLOR_LITERAL : ( '#' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT | '#' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT );
ID : ( ID_LETTER ) ( ( '.' )? ( ID_BODY '.' )* ID_BODY )? ;
fragment ID_BODY : ( ID_LETTER | DIGIT )+ ;
fragment ID_LETTER : [a-zA-Z_] ;
fragment DIGIT : [0-9] ;
fragment ESC : '\\' . ;
fragment DIGITS : DIGIT+ ;
fragment HEX_DIGIT : [0-9a-fA-F] ;
fragment EXP : [eE] [+-]? DIGITS ;
fragment SPACES
 : [ \t]+
 ;

COMMENT : '//' ~[\r\n]* -> skip;
WHITESPACE : [\n ] -> skip;
NEWLINE : (
           ( '\r'? '\n' | '\r' ) SPACES?
          )
{
let spaces = this.text.replace(/[\r\n]+/g, '');
let indent = spaces.length;
if (indent > this.previous()) {
    this.indents.push(indent);
    this.pushToken(SpineParser.INDENT, spaces);
} else if (indent < this.previous()) {
    while (this.previous() > indent) {
        this.pushToken(SpineParser.DEDENT, "");
        this.indents.pop();
    }
} else {
//    this.skip();
}
};

stmts: (call | decl | loop | branch | func)+;
block: INDENT stmts DEDENT;
args: (expr (COMMA expr)* (COMMA decl)*)? (decl (COMMA decl)*)?;
branch: IF_COND expr block (IF_COND_ELSE block)?;
call: ID LPAR args RPAR;
decl: ID ( DEFINE | ASSIGN ) ( expr | branch | tenary );
func: ID LPAR ID* RPAR ARROW block;
hist: ID LSQBR expr RSQBR;
loop: FOR_STMT decl FOR_STMT_TO expr ( FOR_STMT_BY INT_LITERAL )? loop_body;
loop_body: (expr | BREAK | CONTINUE)+;
tenary: expr COND expr COND_ELSE ( LPAR tenary RPAR | tenary | expr );
expr: ( MINUS? ( INT_LITERAL | FLOAT_LITERAL )| BOOL_LITERAL | STR_LITERAL | COLOR_LITERAL ) #Literal
    | (NOT|MINUS)? call #Callexpr
    | (NOT|MINUS)? ( hist | ID ) #Identifier
    | LPAR ( tenary | expr ) RPAR #Group
    | expr ( OR | AND | NOT | EQ | NEQ | GT | GE | LT | LE | PLUS | MINUS | MUL | DIV | MOD ) expr #Op
    ;