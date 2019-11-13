%{
#include <iostream>
#include <string>
#include <map>
#include <set>
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
vector<string> processa_neg(string numero);

void erro(string msg);
void Print(string st);
void print_codigo(vector<string> codigo);

vector<string> resolve_enderecos(vector<string> entrada);

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

%token ID IF FOR WHILE NUM NEGNUM STR LET NARRAY NOBJ
%right '='
%nonassoc '<' '>'
%left '+' '-'
%left '*' '/' '%'

%%

S : CMDS { print_codigo(resolve_enderecos($1.c) + "."); }
  ;

CMDS : CMD ';' CMDS { $$.c = $1.c + $3.c; }
     | CMD ';' { $$.c = $1.c; }
     ;

CMD : DECL {$$.c = $1.c;}
    | E {$$.c = $1.c;}
    | IFS {$$.c = $1.c;}
    ;

DECL : LET DECLS { $$ = $2; }
     ;

DECLS : L ',' DECLS { $$.c = $1.c + "&" + $3.c; registra_variavel($1.v, linha); }
      | ATRL ',' DECLS {$$.c = $1.c + $3.c;}
      | L { $$.c = $1.c + "&"; registra_variavel($1.v, linha); }
      | ATRL {$$.c = $1.c;}
      ;

ATRL : L '=' E {
         registra_variavel($1.v, linha);
         $$.c = $1.c + "&" + $1.c + $3.c  + $2.v + "^";
     }
     ;

ATR : L '=' E { checa_variavel($1.v); $$.c = $1.c + $3.c + $2.v ; }
    | E {$$.c = $1.c;}
    ;

ATRP : LPROP '=' E { checa_variavel($1.v); $$.c = $1.c + $3.c + "[=]"; }
     | E {$$.c = $1.c;}
     ;

IFS : IF '(' E ')' CMD {
        string verdadeiro = gera_label("verdadeiro_then");
        string falso = gera_label("falso_then");
        string def_verdadeiro = ":" + verdadeiro;
        string def_falso = ":" + falso;
        $$.c = $$.c + $3.c + verdadeiro + " ?" +
        falso + " #" + def_verdadeiro +
        $5.c + def_falso;
    }
    ;

E : L '=' ATR { checa_variavel($1.v); $$.c = $1.c + $3.c + $2.v + "^"; }
  | LPROP '=' ATRP { checa_variavel($1.v); $$.c = $1.c + $3.c + "[=]" + "^"; }
  | E '+' E { $$.c = $1.c + $3.c + $2.v; }
  | E '-' E { $$.c = $1.c + $3.c + $2.v; }
  | E '*' E { $$.c = $1.c + $3.c + $2.v; }
  | E '>' E { $$.c = $1.c + $3.c + $2.v; }
  | E '<' E { $$.c = $1.c + $3.c + $2.v; }
  | F
  ;

L : ID {$$.c = $$.c + $1.v; $$.v = $1.v;}
  ;

LPROP : L '[' E ']' {$$.c = $1.c + "@" + $3.c; $$.v = $1.v; }
      | L '.' L {$$.c = $1.c + "@" + $3.c; $$.v = $1.v; }
      | LPROP '.' L {$$.c = $1.c + "[@]" + $3.c; $$.v = $1.v; }
      | LPROP '[' E ']' {$$.c = $1.c + "[@]" + $3.c; $$.v = $1.v; }
      ;

F : L { checa_variavel($1.v); $$.c = $1.c + "@"; }
  | LPROP { checa_variavel($1.v); $$.c = $1.c + "[@]"; }
  | NUM {$$.c = $$.c + $1.v;}
  | STR {$$.c = $$.c + $1.v;}
  | NEGNUM {$$.c = processa_neg($1.v);}
  | NARRAY {$$.c = $$.c + $1.v;}
  | NOBJ {$$.c = $$.c + $1.v;}
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
    yylval.v = yytext;
    coluna += strlen(yytext);
    return tk;
}

vector<string> resolve_enderecos(vector<string> entrada) {
    map<string,int> label;
    vector<string> saida;
    /* string instrucoes[] = {"#", "{}", "[]", "@", "=", "?", "&", "^", "."}; */
    /* int endereco = 0; */

    for(long unsigned int i = 0; i < entrada.size(); i++) {
        /* for (int j = 0; j < 9; j++) { */
        /*     if(entrada[i].find(instrucoes[j]) != string::npos) endereco++; */
        /* } */
        if(entrada[i][0] == ':') {
            label[entrada[i].substr(1)] = saida.size();
        } else {
            saida.push_back(entrada[i]);
        }
    }

    for(long unsigned int i = 0; i < saida.size(); i++) {
        if(label.count(saida[i]) > 0) {
            saida[i] = to_string(label[saida[i]]);
        }
    }

    return saida;
}

void print_codigo(vector<string> codigo) {
    for(long unsigned int i = 0; i < codigo.size(); i++) {
        cout << codigo[i];
    }
}

vector<string> concatena(vector<string> a, vector<string> b) {
    for(long unsigned int i = 0; i < b.size(); i++ ) {
        a.push_back(b[i]);
    }
    return a;
}

vector<string> concatena(vector<string> a, string b) {
    a.push_back(b + " ");
    return a;
}

vector<string> operator+(vector<string> a, vector<string> b) {
    return concatena(a, b);
}

vector<string> operator+(vector<string> a, string b) {
    return concatena(a, b);
}

vector<string> processa_neg(string numero) {
    vector<string> saida;
    saida.push_back("0 ");
    saida.push_back(numero.substr(1) + " ");
    saida.push_back("- ");
    return saida;
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
