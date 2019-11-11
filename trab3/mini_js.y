%{
#include <iostream>
#include <string>
#include <map>
#include <vector>

using namespace std;

struct Atributos {
    vector<string> c;
    string v;
};

#define YYSTYPE Atributos

vector<string> concatena(vector<string> a, vector<string> b);
vector<string> concatena(vector<string> a, string b);
vector<string> operator+(vector<string> a, vector<string> b);
vector<string> operator+(vector<string> a, string b);

void erro(string msg);
void Print(string st);

int yylex();
void yyerror(const char*);
int retorna(int tk);

int linha = 0;
int coluna = 1;
map<string, int> variaveis;

void registra_variavel(string id, int linha);
void checa_variavel(string id);
string gera_label(string prefixo);

%}

%token ID IF NUM STR LET NARRAY NOBJ
%right '='
%nonassoc '<' '>'
%left '+' '-'
%left '*' '/' '%'

%%

S : CMDS { Print("."); }
  ;

CMDS : CMD ';' CMDS
     | CMD ';'
     ;

CMD : DECL
    | E
    ;

DECL : LET DECLS
     ;

DECLS : L { Print("&"); registra_variavel($1.v, linha); } ',' DECLS
      | ATRL ',' DECLS
      | L { Print("&"); registra_variavel($1.v, linha); }
      | ATRL
      ;

ATRL : L '=' { Print("& " + $1.v); registra_variavel($1.v, linha); } E { Print("= ^"); }
     ;

ATR : L { checa_variavel($1.v); Print(""); } '=' E { Print("="); }
    | E
    ;

E : L { checa_variavel($1.v); Print(""); } '=' ATR { Print("= ^"); }
  | E '+' E { Print("+"); }
  | E '*' E { Print("*"); }
  | E '>' E { Print(">"); }
  | E '<' E { Print("<"); }
  | F
  ;

L : ID { $$ = $1; cout << $1.v; }
  ;

F : L { checa_variavel($1.v); Print("@"); }
  | NUM { Print($1.v); }
  | STR { Print($1.v); }
  | NARRAY { Print($1.v); }
  | NOBJ { Print($1.v); }
  ;

%%

#include "lex.yy.c"

// map<int, string> nome_tokens = {
//                                 {LET, "let"},
//                                 {STR, "string"},
//                                 {ID, "nome do identificador"},
//                                 {NUM, "número"}
// };

// string nome_token(int token) {
//   if(nome_tokens.find(token) != nome_tokens.end()) {
//     return nome_tokens[token];
//   } else {
//     string r;
//     r = token;
//     return r;
//   }
// }


int retorna (int tk) {
    yylval.c.push_back(yytext);
    yylval.v = yytext;
    coluna += strlen(yytext);
    return tk;
}

vector<string> concatena(vector<string> a, vector<string> b) {
    for(long unsigned int i = 0; i < b.size(); i++ )
        a.push_back(b[i]);
    return a;
}

vector<string> concatena(vector<string> a, string b) {
    a.push_back(b);
    return a;
}

vector<string> operator+(vector<string> a, vector<string> b) {
    return concatena(a, b);
}

vector<string> operator+(vector<string> a, string b) {
    return concatena(a, b);
}

void registra_variavel(string st, int lin) {
    if (variaveis.find(st) == variaveis.end()) {
        variaveis.insert(make_pair(st, lin));
    } else {
        erro("a variável '" + st + "' já foi declarada na linha " + to_string(lin) + ".");
    }
}

void checa_variavel(string st) {
    if (variaveis.find(st) == variaveis.end()) {
        erro("a variável '" + st + "' não foi declarada.");
    }
}

string gera_label(string prefixo) {
    static int n = 0;
    return prefixo + "_" + to_string(++n) + ":";
}

void erro(string msg) {
    cerr << "Erro: " << msg << endl;
    exit(-1);
}

void yyerror(const char* msg) {
  cerr << endl << "Erro: " << msg << endl
       << "Perto de : '" << yylval.v << "'" << endl;
  exit(-1);
}

void Print (string st) {
  cout << st << " ";
}

int main() {
  yyparse();
  cout << endl;
  return 0;
}
