%option noyywrap

DIGITO  [0-9]
LETRA   [A-Za-z_]

INT     {DIGITO}+
FLOAT	  {INT}("."{INT})?([Ee]("+"|"-")?{INT})?
NFLOAT	(-){INT}("."{INT})?([Ee]("+"|"-")?{INT})?
ID      ({LETRA}|"$"|"_")({LETRA}|{DIGITO}|"$"|"_")*
STRING  (\"([^\"\n]|(\\\")|\"\")+\")|(\'([^\'\n]|(\\\')|\'\')+\')

%%

"\t"        { coluna += 4; }
" "         { coluna++; }
"\n"        { linha++; coluna = 1; }

{NFLOAT}    { return retorna(NEGNUM); }
{FLOAT}     { return retorna(NUM); }
{STRING}    { return retorna(STR); }
"asm{".*"}" { return asm_cod(ASM); }
"let"       { return retorna(LET); }
"function"  { return retorna(FUNC); }
"return"    { return retorna(RET); }
"if"        { return retorna(IF); }
"else"      { return retorna(ELSE); }
"while"     { return retorna(WHILE); }
"for"       { return retorna(FOR); }
"{}"        { return retorna(NOBJ); }
"[]"        { return retorna(NARRAY); }
"=="        { return retorna(_IGUAL); }
{ID}        { return retorna(ID); }
.           { return retorna(*yytext); }

%%
