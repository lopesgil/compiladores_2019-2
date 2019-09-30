%{
#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <iostream>

using namespace std;

extern int yylex();
extern char* yytext;
int token;

void L();
void P();
void A();
void E();
void E_linha();
void T();
void T_linha();
void F();
void casa ( int );

enum { tk_num = 256, tk_print, tk_id, tk_string };

%}

WS		[ \t\n]
DIGITO  [0-9]
LETRA   [A-Za-z_]

INT     {DIGITO}+
FLOAT	{INT}("."{INT})?([Ee]("+"|"-")?{INT})?
ID      ({LETRA}|"$"|"_")({LETRA}|{DIGITO}|"$"|"_")*
STRING  (\"(\"\"|\\.|[^"\\])*\")

%%

{WS}	 { /* ignora espaços, tabs e '\n' */ }
"print"  { return tk_print; }
{FLOAT}  { return tk_num; }
{STRING} { return tk_string; }
{ID}     { return tk_id; }
. 		 { return yytext[0]; }

%%

int next_token() {
	return yylex();
}

void casa(int esperado) {
	if( token == esperado )
		token = next_token();
	else {
		exit(1);
	}
}

void L() {
	switch( token ) {
		case tk_id:
			A();
			break;
		case tk_print:
			P();
			break;

		default:
			cout << "Identificador ou 'print' esperado, encontrado " << token << endl;
			exit( 1 );
	}
	casa( ';' );
}

void P() {
	casa(tk_print);
	E();
	cout << "print # ";
}

void A() {
	string temp(yytext);
	casa( tk_id );
	cout << temp << " ";
	casa('=');
	E();
	cout << "= ";
}

void E() {
	T();
	E_linha();
}

void E_linha() {
	switch( token ) {
		case '+' :
			casa( '+' );
			T();
			cout << "+ ";
			E_linha();
			break;
		case '-' :
			casa( '-' );
			T();
			cout << "- ";
			E_linha();
			break;
	}
}

void T() {
	F();
	T_linha();
}

void T_linha() {
	switch( token ) {
		case '*' :
			casa( '*' );
			F();
			cout << "* ";
			T_linha();
			break;
		case '/' :
			casa( '/' );
			F();
			cout << "/ ";
			T_linha();
			break;
	}
}

void F() {
	switch( token ) {
		case tk_id : {
			string temp(yytext);
			casa( tk_id ); cout << temp << " @ ";
			}
			break;
		case tk_num : {
			string temp(yytext);
			casa( tk_num ); cout << temp << " ";
			}
			break;
		case tk_string : {
			string temp(yytext);
			casa( tk_string ); cout << temp << " ";
			}
			break;
		case '(':
			casa( '(' ); E(); casa( ')' ); break;
		default :
			cout << "Operando esperado, encontrado " << yytext << endl;
	}
}

int main() {
	token = next_token();
	while(token) {
		L();
	}
	return 0;
}

// Deve ser um arquivo lex com o seu analisador sintático na parte final
