%option noyywrap

DIGITO  [0-9]
LETRA   [A-Za-z_]

INT     {DIGITO}+
FLOAT	  (-?){INT}("."{INT})?([Ee]("+"|"-")?{INT})?
ID      ({LETRA}|"$"|"_")({LETRA}|{DIGITO}|"$"|"_")*
STRING  (\"([^\"\n]|(\\\")|\"\")+\")|(\'([^\'\n]|(\\\')|\'\')+\')

%%

"\t"        { coluna += 4; }
" "         { coluna++; }
"\n"        { linha++; coluna = 1; }

{FLOAT}     { return retorna(NUM); }
{STRING}    { return retorna(STR); }
"let"       { return retorna(LET); }
"if"        { return retorna(IF); }
"{}"        { return retorna(NOBJ); }
"[]"        { return retorna(NARRAY); }
{ID}        { return retorna(ID); }
.           { return retorna(*yytext); }

%%
