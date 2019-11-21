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
int asm_cod(int tk);

string trim(string st, string dl);
vector<string> tokeniza(string st);

int linha = 0;
int coluna = 1;
map<string, int> variaveis;
vector<string> c_funcoes;

void registra_variavel(string id, int linha);
void checa_variavel(string id);
string gera_label(string prefixo);

int num_args;

%}

%token ID ASM FUNC RET IF ELSE FOR WHILE NUM NEGNUM STR LET NARRAY NOBJ
%right '='
%nonassoc '<' '>' _IGUAL
%left '+' '-'
%left '*' '/' '%'

%%

S : CMDS { print_codigo(resolve_enderecos($1.c + "." + c_funcoes)); }
  ;

CMDS : CMD ';' CMDS { $$.c = $1.c + $3.c; }
     | CMD ';' { $$.c = $1.c; }
     | BLS CMDS { $$.c = $1.c + $2.c; }
     | BLS { $$.c = $1.c; }
     ;

BLS : FUNS {$$.c = $1.c;}
    | IFS {$$.c = $1.c;}
    ;

CMD : DECL {$$.c = $1.c;}
    | E {$$.c = $1.c;}
    | RETUR {$$.c = $1.c;}
    | E ASM { $$.c = $1.c + $2.c + "^";}
    ;

FUNS : FUNC L '(' {/* registra_variavel($2.v, linha);*/ num_args = 0;} PARAMS ')' BLOCO {
         string endereco = gera_label($2.v);
         string def_endereco = ":" + endereco;
         $$.c = $2.c + "&" + $2.c + "{}" + "=" + "'&funcao'" + endereco + " [=]" + "^";
         c_funcoes = c_funcoes + def_endereco + $5.c + $7.c +
         "undefined" + "@" + "'&retorno'" + "@" + "~";
     }
     ;

PARAMS : PARAM
       |
       ;

PARAM : PARAM ',' L { /* registra_variavel($3.v, linha);*/ $$.c = $3.c + "&" + $3.c + "arguments" +
       "@" + to_string(num_args++) + "[@]" + "=" + "^" + $1.c; }
      | L { /* registra_variavel($1.v, linha);*/ $$.c = $1.c + "&" + $1.c + "arguments" +
       "@" + to_string(num_args++) + "[@]" + "=" + "^"; }
      ;

RETUR : RET E {$$.c = $2.c + "'&retorno'" + "@" + "~";}
      ;

BLOCO : '{' CMDS '}' {$$.c = $2.c;}
      ;

DECL : LET DECLS { $$ = $2; }
     ;

DECLS : L ',' DECLS { $$.c = $1.c + "&" + $3.c; /* registra_variavel($1.v, linha);*/ }
      | ATRL ',' DECLS {$$.c = $1.c + $3.c; }
      | L { $$.c = $1.c + "&"; /* registra_variavel($1.v, linha);*/ }
      | ATRL {$$.c = $1.c;}
      ;

ATRL : L '=' E {
         /* registra_variavel($1.v, linha);*/
         $$.c = $1.c + "&" + $1.c + $3.c  + $2.v + "^" ;
     }
     ;

ATR : L '=' E { /* checa_variavel($1.v);*/ $$.c = $1.c + $3.c + $2.v ; }
    | E {$$.c = $1.c;}
    ;

ATRP : LPROP '=' E { /* checa_variavel($1.v);*/ $$.c = $1.c + $3.c + "[=]"; }
     | E {$$.c = $1.c;}
     ;

IFS : IFSIMPLES
    | IFELSE
    ;

IFSIMPLES : IF '(' E ')' CMD ';' {
              string verdadeiro = gera_label("verdadeiro_then");
              string falso = gera_label("falso_then");
              string def_verdadeiro = ":" + verdadeiro;
              string def_falso = ":" + falso;
              $$.c = $$.c + $3.c + verdadeiro + " ?" +
              falso + " #" + def_verdadeiro +
              $5.c + def_falso;
          }
          | IF '(' E ')' BLOCO {
              string verdadeiro = gera_label("verdadeiro_then");
              string falso = gera_label("falso_then");
              string def_verdadeiro = ":" + verdadeiro;
              string def_falso = ":" + falso;
              $$.c = $$.c + $3.c + verdadeiro + " ?" + falso +
              " #" + def_verdadeiro + $5.c + def_falso;
          }
          ;

IFELSE : IF '(' E ')' CMD ';' ELSE CMD ';' {
           string fim_if = gera_label("fim_if_then");
           string verdadeiro = gera_label("verdadeiro_then");
           string def_fim_if = ":" + fim_if;
           string def_verdadeiro = ":" + verdadeiro;
           $$.c = $$.c + $3.c + verdadeiro + " ?" + $8.c + fim_if + " #" +
                  def_verdadeiro + $5.c + def_fim_if;
       }
       | IF '(' E ')' BLOCO ELSE CMD ';'
       | IF '(' E ')' CMD ';' ELSE BLOCO
       | IF '(' E ')' BLOCO ELSE BLOCO
       ;

CALFUN : ID '(' {num_args = 0;} ARGS ')' {
           string n = to_string(num_args);
           $$.c.clear(); $$.c = $$.c + $4.c + n + $1.v + "@" + "$";
       }
       | ID '(' ')' { $$.c.clear(); $$.c = $$.c + "0" + $1.v + "@" + "$"; }
       ;

ARGS : ARG {$$.c = $1.c;}
     |
     ;

ARG : E ',' ARG {num_args++; $$.c = $1.c + $3.c;}
    | E {num_args++; $$.c = $1.c; }
    ;

E : L '=' ATR { /* checa_variavel($1.v);*/ $$.c = $1.c + $3.c + $2.v + "^"; }
  | LPROP '=' ATRP { /* checa_variavel($1.v);*/ $$.c = $1.c + $3.c + "[=]" + "^"; }
  | E '+' E { $$.c = $1.c + $3.c + $2.v; }
  | E '-' E { $$.c = $1.c + $3.c + $2.v; }
  | E '*' E { $$.c = $1.c + $3.c + $2.v; }
  | E '%' E { $$.c = $1.c + $3.c + $2.v; }
  | E '/' E { $$.c = $1.c + $3.c + $2.v; }
  | E '>' E { $$.c = $1.c + $3.c + $2.v; }
  | E '<' E { $$.c = $1.c + $3.c + $2.v; }
  | E _IGUAL E { $$.c = $1.c + $3.c + $2.v; }
  | CALFUN
  | F
  ;

L : ID {$$.c.clear(); $$.c = $$.c + $1.v; $$.v = $1.v;}
  ;

LPROP : L '[' E ']' {$$.c = $1.c + "@" + $3.c; $$.v = $1.v; }
      | L '.' L {$$.c = $1.c + "@" + $3.c; $$.v = $1.v; }
      | LPROP '.' L {$$.c = $1.c + "[@]" + $3.c; $$.v = $1.v; }
      | LPROP '[' E ']' {$$.c = $1.c + "[@]" + $3.c; $$.v = $1.v; }
      ;

F : L { /* checa_variavel($1.v);*/ $$.c = $1.c + "@"; }
  | LPROP { /* checa_variavel($1.v);*/ $$.c = $1.c + "[@]"; }
| NUM {$$.c.clear();$$.c = $$.c + $1.v;}
  | STR {$$.c.clear(); $$.c = $$.c + $1.v;}
| NEGNUM {$$.c.clear();$$.c = processa_neg($1.v);}
| NARRAY {$$.c.clear();$$.c = $$.c + $1.v;}
| NOBJ {$$.c.clear();$$.c = $$.c + $1.v;}
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

string trim(string st, string dl) {
    string ret;
    ret.reserve(st.size());
        for(size_t j = 0; j < st.length(); j++) {
            if(st[j] != '{' && st[j] != '}') ret += st[j];
        }
    return ret;
}

vector<string> tokeniza(string st) {
    vector<string> ret;
    string temp = st.substr();
    size_t pos = 0;
    string token;
    while((pos = temp.find(" ")) != string::npos) {
        token = temp.substr(0, pos);
        ret.push_back(token + " ");
        temp.erase(0, pos + 1);
    }
    ret.push_back(temp + " ");
    return ret;
}

int asm_cod (int tk) {
    string lexema = trim(yytext + 3, "{}");
    yylval.c = tokeniza(lexema);
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
       << "Perto de : '" << yylval.v << "' na posição " << linha << "; " << coluna << endl;
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
