/* Coloque aqui definições regulares */

WS	[ \t\n]
DIGITO  [0-9]
LETRA   [A-Za-z_]

COMMEN  (\/\*[^*]*\*+([^\/][^*]*\*+)*\/|\/\/.*)
INT     {DIGITO}+
FLOAT	{INT}("."{INT})?([Ee]("+"|"-")?{INT})?
FOR     [Ff][Oo][Rr]
IF      [Ii][Ff]
ID      ({LETRA}|"$"|"_")({LETRA}|{DIGITO}|"$"|"_")*
STRING  (\"(\\.|[^"\\])*\")

%%
    /* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

{WS}	 { /* ignora espaços, tabs e '\n' */ } 
{COMMEN} { return _COMENTARIO; }
{INT}    { return _INT; }
{FLOAT}  { return _FLOAT; }
{STRING} { return _STRING; }  
{FOR}    { return _FOR; }
{IF}     { return _IF; }
">="     { return _MAIG; }
{ID}     { return _ID; }
"<="     { return _MEIG; }
"=="     { return _IG; }
"!="     { return _DIF; }
.        { return *yytext; 
          /* Essa deve ser a última regra. Dessa forma qualquer caractere isolado será retornado pelo seu código ascii. */ }

%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */
