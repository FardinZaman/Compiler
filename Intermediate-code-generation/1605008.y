%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include <bits/stdc++.h>
#include "1605008_symbol_table.h"


//#define YYSTYPE symbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int yylineno;

FILE *fp;
FILE *error = fopen("error.txt","w");
FILE *logfile = fopen("log.txt","w");


bool receiver = false;

int line_count = 1;
int error_count = 0;
int track_line = 0;
string comment = "";
int start = 0;
//bool catch;
string all;
string token;

//FILE *log_output;
//FILE *token_output;

char return_real_value(char ch)
{
    if(ch = 'n')
        return '\n';
    if(ch = 't')
        return '\t';
    if(ch = 'a')
        return '\a';
    if(ch = 'f')
        return '\f';
    if(ch = 'r')
        return '\r';
    if(ch = 'b')
        return '\b';
    if(ch = 'v')
        return '\v';
    if(ch = '0')
        return '\0';
    if(ch = '\"')
        return '\"';
    if(ch = '\'')
        return '\'';
    if(ch = '\\')
        return '\\';
}

symbol_table st;
scope_table* sc = new scope_table(7);

string function_return;

vector<symbolInfo*>parameters;
vector<symbolInfo*>declarations;
vector<symbolInfo*>argumentss;

vector<string>variables;
vector<string>function_variables;
vector<pair<string,string>>arrays;

void yyerror(const char *s)
{
	//write your code
}

int labelCount=0;
int tempCount=0;

void optimization(FILE *assembly);

char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
}

string int_to_string (int a)
{
    ostringstream temp;
    temp<<a;
    return temp.str();
}


%}

%union
{
      symbolInfo* symbolinfo;
}

%token <symbolinfo>IF FOR WHILE DO BREAK CHAR DOUBLE RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN
%token <symbolinfo>INT FLOAT VOID CONST_INT CONST_FLOAT CONST_CHAR
%token <symbolinfo>NEWLINE
%token <symbolinfo>ASSIGNOP INCOP DECOP NOT
%token <symbolinfo>LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON


%left <symbolinfo>ADDOP MULOP LOGICOP BITOP RELOP

%nonassoc DUMMY
%nonassoc ELSE

%nonassoc DUMMY2
%nonassoc SEMICOLON


%token <symbolinfo>ID 

%type <symbolinfo> start program unit func_declaration func_definition parameter_list compound_statement declaration_list statements var_declaration type_specifier
%type <symbolinfo> statement expression expression_statement variable logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

%%

start : program { $$ = new symbolInfo();
                  fprintf(logfile,"At line no %d : start : program\n\n",yylineno-1);
	          fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                  $$->set_name($1->get_name());
                  if(error_count==0){	
	               string codes = "";
	               codes += ".MODEL SMALL\n\.STACK 100H\n\.DATA \n";
	               for(int i=0;i<variables.size();i++){
		            codes += variables[i] + " dw ?\n";
	               }
	               for(int i=0;i<arrays.size();i++){
		            codes += arrays[i].first + " dw " + arrays[i].second + " dup(?)\n";
	               }
	               $$->set_code(codes + ".CODE\n" + $1->get_code());
             	       $$->set_code($$->get_code() + "OUTDEC PROC  \n\ 
    PUSH AX \n\ 
    PUSH BX \n\ 
    PUSH CX \n\ 
    PUSH DX  \n\ 
    CMP AX,0 \n\ 
    JGE BEGIN \n\ 
    PUSH AX \n\ 
    MOV DL,'-' \n\ 
    MOV AH,2 \n\ 
    INT 21H \n\ 
    POP AX \n\ 
    NEG AX \n\ 
    \n\ 
    BEGIN: \n\ 
    XOR CX,CX \n\ 
    MOV BX,10 \n\ 
    \n\ 
    REPEAT: \n\ 
    XOR DX,DX \n\ 
    DIV BX \n\ 
    PUSH DX \n\ 
    INC CX \n\ 
    OR AX,AX \n\ 
    JNE REPEAT \n\ 
    MOV AH,2 \n\ 
    \n\ 
    PRINT_LOOP: \n\ 
    POP DX \n\ 
    ADD DL,30H \n\ 
    INT 21H \n\ 
    LOOP PRINT_LOOP \n\ 
    \n\    
    MOV AH,2\n\
    MOV DL,10\n\
    INT 21H\n\
    \n\
    MOV DL,13\n\
    INT 21H\n\
	\n\
    POP DX \n\ 
    POP CX \n\ 
    POP BX \n\ 
    POP AX \n\ 
    ret \n\ 
OUTDEC ENDP \n\
END MAIN\n");
                       FILE* assembly =  fopen("code.asm","w");
	               fprintf(assembly,"%s",$$->get_code().c_str());
	               fclose(assembly);
	               assembly = fopen("code.asm","r");
	               optimization(assembly);
	          }
                }
	;

program : program unit { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : program : program unit \n\n",yylineno);
			 fprintf(logfile,"%s %s\n\n",$1->get_name().c_str(),$2->get_name().c_str());
			 $$->set_name($1->get_name() + $2->get_name());
                         $$->set_code($1->get_code() + $2->get_code());
                       } 
	| unit { $$ = new symbolInfo();
                 fprintf(logfile,"At line no %d : program : unit\n\n",yylineno);
	         fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                 $$->set_name($1->get_name());
                 $$->set_code($1->get_code());
               }
	;
	
unit : var_declaration { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : unit : var_declaration\n\n",yylineno);
	                 fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                         $$->set_name($1->get_name() + "\n");
                         function_variables.clear();
                         $$->set_code($1->get_code());
                       }
     | func_declaration { $$ = new symbolInfo();
                          fprintf(logfile,"At line no %d : unit : func_declaration\n\n",yylineno);
	                  fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                          $$->set_name($1->get_name() + "\n");
                          $$->set_code($1->get_code());
                        }
     | func_definition { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : unit : func_definition\n\n",yylineno);
	                 fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                         $$->set_name($1->get_name() + "\n");
                         $$->set_code($1->get_code());
                       }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON { $$ = new symbolInfo();
                                                                              fprintf(logfile,"At line no %d : func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n",yylineno);
			                                                      fprintf(logfile,"%s %s(%s);\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$4->get_name().c_str());               
			                                                      $$->set_name($1->get_name() + $2->get_name() + "(" + $4->get_name() + ");");
                                                                              symbolInfo *s = new symbolInfo();
                                                                              s = st.look_up($2->get_name());
				                                              if(s == 0){
					                                          st.insert_symbol($2->get_name(),"ID","function");
					                                          s = st.look_up($2->get_name());
					                                          s->set_function();
					                                          for(int i=0;i<parameters.size();i++){
						                                      s->function->add_parameter(parameters[i]->get_name(),parameters[i]->get_realtype());
					                                          }
					                                          parameters.clear();
                                                                                  s->function->set_return_type($1->get_name());
				                                              }
                                                                              else{
                                                                                  error_count++;
                                                                                  fprintf(error,"Error at line no %d : Declared before \n\n",yylineno);
                                                                              } 
                                                                            }
                | type_specifier ID LPAREN parameter_list RPAREN %prec DUMMY2 { $$ = new symbolInfo();
                                                                              fprintf(logfile,"At line no %d : func_declaration : type_specifier ID LPAREN parameter_list RPAREN \n\n",yylineno);
			                                                      fprintf(logfile,"%s %s(%s)\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$4->get_name().c_str());               
			                                                      $$->set_name($1->get_name() + $2->get_name() + "(" + $4->get_name() + ")");
                                                                              symbolInfo *s = new symbolInfo();
                                                                              s = st.look_up($2->get_name());
				                                              if(s == 0){
					                                          st.insert_symbol($2->get_name(),"ID","function");
					                                          s = st.look_up($2->get_name());
					                                          s->set_function();
					                                          for(int i=0;i<parameters.size();i++){
						                                      s->function->add_parameter(parameters[i]->get_name(),parameters[i]->get_realtype());
					                                          }
					                                          parameters.clear();
                                                                                  s->function->set_return_type($1->get_name());
				                                              }
                                                                              else{
                                                                                  error_count++;
                                                                                  fprintf(error,"Error at line no %d : Declared before \n\n",yylineno);
                                                                              }
                                                                              error_count++;
                                                                              fprintf(error,"Error at line no %d : Expected Semicolon \n\n",yylineno); 
                                                                            }
		| type_specifier ID LPAREN RPAREN SEMICOLON { $$ = new symbolInfo();
                                                              fprintf(logfile,"At line no %d : func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n",yylineno);
			                                      fprintf(logfile,"%s %s();\n\n",$1->get_name().c_str(),$2->get_name().c_str()); 
			                                      $$->set_name($1->get_name() + $2->get_name() + "();");
                                                              symbolInfo *s = new symbolInfo();
                                                              s = st.look_up($2->get_name());
				                              if(s == 0){
                                                                  //printf();
					                          st.insert_symbol($2->get_name(),"ID","function");
					                          s = st.look_up($2->get_name());
					                          s->set_function();
                                                                  //s->function = new Function();
                                                                  s->function->set_return_type($1->get_name());
                                                                  //printf("%s",s->function->get_return_type().c_str());
                                                                  //s = st.look_up($2->get_name());
                                                                  /*if(s->function != 0)
                                                                      printf("%s",s->get_realtype().c_str());*/
				                              }
                                                              else{
                                                                  error_count++;
                                                                  fprintf(error,"Error at line no %d : Declared before \n\n",yylineno);
                                                              }
                                                            }
                | type_specifier ID LPAREN RPAREN %prec DUMMY2 { $$ = new symbolInfo();
                                                              fprintf(logfile,"At line no %d : func_declaration : type_specifier ID LPAREN RPAREN \n\n",yylineno);
			                                      fprintf(logfile,"%s %s()\n\n",$1->get_name().c_str(),$2->get_name().c_str()); 
			                                      $$->set_name($1->get_name() + $2->get_name() + "()");
                                                              symbolInfo *s = new symbolInfo();
                                                              s = st.look_up($2->get_name());
				                              if(s == 0){
                                                                  //printf();
					                          st.insert_symbol($2->get_name(),"ID","function");
					                          s = st.look_up($2->get_name());
					                          s->set_function();
                                                                  //s->function = new Function();
                                                                  s->function->set_return_type($1->get_name());
                                                                  //printf("%s",s->function->get_return_type().c_str());
                                                                  //s = st.look_up($2->get_name());
                                                                  /*if(s->function != 0)
                                                                      printf("%s",s->get_realtype().c_str());*/
				                              }
                                                              else{
                                                                  error_count++;
                                                                  fprintf(error,"Error at line no %d : Declared before \n\n",yylineno);
                                                              }
                                                              error_count++;
                                                              fprintf(error,"Error at line no %d : Expected Semicolon \n\n",yylineno);
                                                            }
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN { //$$ = new symbolInfo();
                                                                   symbolInfo *s = new symbolInfo();
                                                                   s = st.look_up($2->get_name());
                                                                   if(s == 0){
					                               st.insert_symbol($2->get_name(),"ID","function");
					                               s = st.look_up($2->get_name());
					                               s->set_function();
                                                                       s->function->set_defined();
					                               for(int i=0;i<parameters.size();i++){
						                           s->function->add_parameter(parameters[i]->get_name()+int_to_string(st.id_track),parameters[i]->get_realtype());
					                               }
					                               //parameters.clear();
                                                                       s->function->set_return_type($1->get_name());
				                                   }
                                                                   else if(s->function == 0){
                                                                       fprintf(error,"Error at line no %d : %s Not declared as a function \n\n",yylineno,s->get_name().c_str());
                                                                       error_count++;  
                                                                   }
                                                                   else{
                                                                       if(s->function->get_defined() == 0){
					                                   int number = s->function->get_number_of_parameters();
				                                           if(number != parameters.size()){
						                               error_count++;
						                               fprintf(error,"Error at line no %d : Invalid number of parameters \n\n",yylineno);
                                                                           }
                                                                           else{
					                                       vector<string>parameter_type = s->function->get_parameter_type_list();
					                                       for(int i=0 ; i<parameters.size() ; i++){
					                                           if(parameters[i]->get_realtype() != parameter_type[i]){
								                       error_count++;
								                       fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
								                       break;
							                           }
						                               }
						                               if(s->function->get_return_type() != $1->get_name()){
								                   error_count++;
								                   fprintf(error,"Error at line no %d : Return Type Mismatch \n\n",yylineno);
						                               }
					                                   }
					                                   s->function->set_defined();
                                                                       }
					                               else{
						                           error_count++;
						                           fprintf(error,"Error at line no %d : Multiple defination of function %s\n\n",yylineno,$2->get_name().c_str());
								       }
                                                                   }
                                                                   function_return = $2->get_name();
						                   variables.push_back(function_return + "_return");
                                                                 }compound_statement { $$ = new symbolInfo();
                                                                                       fprintf(logfile,"At line no %d : func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",yylineno);                                                     fprintf(logfile,"%s %s(%s) %s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$4->get_name().c_str(),$7->get_name().c_str());
                                                                                       $$->set_code($2->get_name() + " PROC\n");
									               if($2->get_name() == "main"){
									                   $$->set_code($$->get_code() + "    MOV AX,@DATA\n\tMOV DS,AX \n" + $7->get_code() + "LReturn" + function_return + ":\n\tMOV AH,4CH\n\tINT 21H\n");
									               }
									               else{
									                   symbolInfo *s = st.look_up($2->get_name()); 
                                                                                           for(int i=0;i<function_variables.size();i++){
										               s->function->add_variable(function_variables[i]);
									                   }
								                           function_variables.clear();
									                   string codes = $$->get_code() + "\tPUSH AX\n\tPUSH BX \n\tPUSH CX \n\tPUSH DX\n";
									                   vector<string>parameter_list = s->function->get_parameter_list();
									                   vector<string>variable_list = s->function->get_variable_list();
									                   for(int i=0;i<parameter_list.size();i++){
										               codes += "\tPUSH " + parameter_list[i]+"\n";
									                   }
									                   for(int i=0;i<variable_list.size();i++){
										               codes += "\tPUSH " + variable_list[i]+"\n";
									                   }
									                   codes += $7->get_code() + "LReturn" + function_return + ":\n";
									                   for(int i=variable_list.size()-1;i>=0;i--){
										               codes += "\tPOP " + variable_list[i] + "\n";
									                   }
									                   for(int i=parameter_list.size()-1;i>=0;i--){
										               codes += "\tPOP " + parameter_list[i] + "\n";
									                   }
									                   codes += "\tPOP DX\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tret\n";		
									                   //$$->set_code(codes + $2->get_name() + " ENDP\n");
                                                                                           $$->set_code(codes);
								                       }
                                                                                       $$->set_code($$->get_code() + $2->get_name() + " ENDP\n");                 
			                                                               $$->set_name($1->get_name() + $2->get_name() + "(" + $4->get_name() + ")" + $7->get_name());
                                                                                     }
		| type_specifier ID LPAREN RPAREN { //$$ = new symbolInfo();
                                                    symbolInfo *s = new symbolInfo();
                                                    s = st.look_up($2->get_name());
                                                    if(s == 0){
                                                        //printf("no");
					                st.insert_symbol($2->get_name(),"ID","function");
					                s = st.look_up($2->get_name());
					                s->set_function();
                                                        s->function->set_defined();
                                                        s->function->set_return_type($1->get_name());
				                    }
                                                    else{
                                                        //if(s->function == 0)
                                                            //printf("%s",s->get_name().c_str());
                                                        if(s->function->get_defined() == 0){
					                    //int number = s->function->get_number_of_parameters();
				                            if(s->function->get_number_of_parameters() != 0){
						                error_count++;
						                fprintf(error,"Error at line no %d : Invalid number of parameters \n\n",yylineno);
                                                            }
						            if(s->function->get_return_type() != $1->get_name()){
								error_count++;
								fprintf(error,"Error at line no %d : Return Type Mismatch \n\n",yylineno);
						            }
					                    s->function->set_defined();
                                                        }
					                else{
						            error_count++;
						            fprintf(error,"Error at line no %d : Multiple defination of function %s\n\n",yylineno,$2->get_name().c_str());
				                        }
                                                    }
                                                    function_return = $2->get_name();
						    variables.push_back(function_return + "_return");               
                                                  }compound_statement { $$ = new symbolInfo();
                                                                        fprintf(logfile,"At line no %d : func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n",yylineno);
			                                                fprintf(logfile,"%s %s() %s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$6->get_name().c_str());
                                                                        $$->set_code($2->get_name() + " PROC\n");
									if($2->get_name() == "main"){
									    $$->set_code($$->get_code() + "    MOV AX,@DATA\n\tMOV DS,AX \n" + $6->get_code() + "LReturn" + function_return + ":\n\tMOV AH,4CH\n\tINT 21H\n");
									}
									else{
									    symbolInfo *s = st.look_up($2->get_name()); 
                                                                            for(int i=0;i<function_variables.size();i++){
										s->function->add_variable(function_variables[i]);
									    }
								            function_variables.clear();
									    string codes = $$->get_code() + "\tPUSH AX\n\tPUSH BX \n\tPUSH CX \n\tPUSH DX\n";
									    vector<string>parameter_list = s->function->get_parameter_list();
									    vector<string>variable_list = s->function->get_variable_list();
									    for(int i=0;i<parameter_list.size();i++){
										codes += "\tPUSH " + parameter_list[i]+"\n";
									    }
									    for(int i=0;i<variable_list.size();i++){
										codes += "\tPUSH " + variable_list[i]+"\n";
									    }
									    codes += $6->get_code() + "LReturn" + function_return + ":\n";
									    for(int i=variable_list.size()-1;i>=0;i--){
										codes += "\tPOP " + variable_list[i] + "\n";
									    }
									    for(int i=parameter_list.size()-1;i>=0;i--){
										codes += "\tPOP " + parameter_list[i] + "\n";
									    }
									    codes += "\tPOP DX\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tret\n";		
									    //$$->set_code(codes + $2->get_name() + " ENDP\n");
                                                                            $$->set_code(codes);
								        }
                                                                        $$->set_code($$->get_code() + $2->get_name() + " ENDP\n"); 
			                                                $$->set_name($1->get_name() + $2->get_name() + "()" + $6->get_name());
                                                                      }
 		;				


parameter_list  : parameter_list COMMA type_specifier ID { $$ = new symbolInfo();
                                                           fprintf(logfile,"At line no %d : parameter_list  : parameter_list COMMA type_specifier ID\n\n",yylineno);
			                                   fprintf(logfile,"%s,%s %s\n\n",$1->get_name().c_str(),$3->get_name().c_str(),$4->get_name().c_str());
                                                           symbolInfo* s = new symbolInfo();
                                                           s->set_name($4->get_name());
                                                           s->set_type("ID");
                                                           s->set_realtype($3->get_name()); 
                                                           parameters.push_back(s);
			                                   $$->set_name($1->get_name() + "," + $3->get_name() + $4->get_name());
                                                         }
		| parameter_list COMMA type_specifier { $$ = new symbolInfo();
                                                        fprintf(logfile,"At line no %d : parameter_list : parameter_list COMMA type_specifier \n\n",yylineno);
			                                fprintf(logfile,"%s,%s\n\n",$1->get_name().c_str(),$3->get_name().c_str());
                                                        symbolInfo* s = new symbolInfo();
                                                        s->set_name("");
                                                        s->set_type("ID");
                                                        s->set_realtype($3->get_name()); 
                                                        parameters.push_back(s);
			                                $$->set_name($1->get_name() + "," + $3->get_name());
                                                      }
 		| type_specifier ID { $$ = new symbolInfo();
                                      fprintf(logfile,"At line no %d : parameter_list : type_specifier ID \n\n",yylineno);
			              fprintf(logfile,"%s %s\n\n",$1->get_name().c_str(),$2->get_name().c_str());
                                      symbolInfo* s = new symbolInfo();
                                      s->set_name($2->get_name());
                                      s->set_type("ID");
                                      s->set_realtype($1->get_name()); 
                                      parameters.push_back(s);
			              $$->set_name($1->get_name() + $2->get_name());
                                    }
		| type_specifier { $$ = new symbolInfo();
                                   fprintf(logfile,"At line no %d : parameter_list : type_specifier\n\n",yylineno);
	                           fprintf(logfile,"%s\n\n",$1->get_name().c_str());
                                   symbolInfo* s = new symbolInfo();
                                   s->set_name("");
                                   s->set_type("ID");
                                   s->set_realtype($1->get_name()); 
                                   parameters.push_back(s); 
                                   $$->set_name($1->get_name());
                                 }
 		;

 		
compound_statement : LCURL { scope_table* sct = new scope_table(7);
                             st.enter_scope(sct);
                             for(int i=0;i<parameters.size();i++){
				  st.insert_symbol(parameters[i]->get_name(),"ID",parameters[i]->get_realtype());
                                  variables.push_back(parameters[i]->get_name() + int_to_string(st.current_scope->id));
                             }
		             parameters.clear();
                           } statements RCURL { $$ = new symbolInfo();
                                                fprintf(logfile,"At line no %d : compound_statement : LCURL statements RCURL\n\n",yylineno);
	                                        fprintf(logfile,"{\n%s\n}\n\n",$3->get_name().c_str()); 
                                                $$->set_name("{\n" + $3->get_name() + "\n" + "}");
                                                $$->set_code($3->get_code());
                                                st.print_all();
                                                st.exit_scope();
                                              }
 		    | LCURL RCURL { scope_table* sct = new scope_table(7);
                                    st.enter_scope(sct);
                                    for(int i=0;i<parameters.size();i++){
				          st.insert_symbol(parameters[i]->get_name(),"ID",parameters[i]->get_realtype());
                                          variables.push_back(parameters[i]->get_name() + int_to_string(st.current_scope->id));
                                    }
				    parameters.clear();
                                    $$ = new symbolInfo();
                                    fprintf(logfile,"At line no %d : compound_statement : LCURL RCURL\n\n",yylineno);
	                            fprintf(logfile,"{\n}\n\n"); 
                                    $$->set_name("{\n}");
                                    st.print_all();
                                    st.exit_scope();
                                  }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON { $$ = new symbolInfo();
                                                              fprintf(logfile,"At line no %d : var_declaration : type_specifier declaration_list SEMICOLON \n\n",yylineno);
			                                      fprintf(logfile,"%s %s;\n\n",$1->get_name().c_str(),$2->get_name().c_str());
			                                      $$->set_name($1->get_name() + $2->get_name() + ";");
                                                              if($1->get_name() == "void"){
								  error_count++;
								  fprintf(error,"Error at line no %d : Type specifier can't be void \n\n",yylineno);
							      }
                                                              else{
                                                                  for(int i=0;i<declarations.size();i++){
				                                      if(st.look_up_current(declarations[i]->get_name()) != 0){
									   error_count++;
									   fprintf(error,"Error at Line No %d : Multiple declaration of %s \n\n",yylineno,declarations[i]->get_name().c_str());
                                                                      }
                                                                      else if(declarations[i]->get_type().size() > 2){
                                                                           //declarations[i]->set_type("ID");
                                                                           st.insert_symbol(declarations[i]->get_name(),"ID",$1->get_name() + "array");
                                                                           arrays.push_back(make_pair(declarations[i]->get_name() + int_to_string(st.current_scope->id),declarations[i]->get_type().substr(2,declarations[i]->get_type().size() - 1)));
                                                                           declarations[i]->set_type("ID");
                                                                           //cout<<123<<endl;   
                                                                      }
                                                                      else{
                                                                           st.insert_symbol(declarations[i]->get_name(),"ID",$1->get_name());
                                                                           function_variables.push_back(declarations[i]->get_name() + int_to_string(st.current_scope->id));
                                                                           variables.push_back(declarations[i]->get_name() + int_to_string(st.current_scope->id));
                                                                      }
                                                                      //cout<<declarations[i]->get_name()<<endl; 
                                                                  }
                                                              }
                                                              declarations.clear();
                                                              //cout<<123<<endl;
                                                              //cout<<st.look_up("c")->get_name()<<endl;
                                                            }
               | type_specifier declaration_list %prec DUMMY2 { $$ = new symbolInfo();
                                                              //line_count = yylineno;
                                                              fprintf(logfile,"At line no %d : var_declaration : type_specifier declaration_list \n\n",yylineno);
			                                      fprintf(logfile,"%s %s\n\n",$1->get_name().c_str(),$2->get_name().c_str());
			                                      $$->set_name($1->get_name() + $2->get_name());
                                                              if($1->get_name() == "void"){
								  error_count++;
								  fprintf(error,"Error at line no %d : Type specifier can't be void \n\n",yylineno);
							      }
                                                              else{
                                                                  for(int i=0;i<declarations.size();i++){
				                                      if(st.look_up_current(declarations[i]->get_name()) != 0){
									   error_count++;
									   fprintf(error,"Error at Line No %d : Multiple declaration of %s \n\n",yylineno-1,declarations[i]->get_name().c_str());
                                                                      }
                                                                      else if(declarations[i]->get_type() == "ID_ARRAY"){
                                                                           declarations[i]->set_type("ID");
                                                                           st.insert_symbol(declarations[i]->get_name(),"ID",$1->get_name() + "array");
                                                                      }
                                                                      else
                                                                           st.insert_symbol(declarations[i]->get_name(),"ID",$1->get_name()); 
                                                                  }
                                                              }
                                                              declarations.clear();
                                                              error_count++;
                                                              fprintf(error,"Error at line no %d : Expected Semicolon \n\n",yylineno);
                                                            }
 		 ;
 		 
type_specifier	: INT { $$ = new symbolInfo();
                        fprintf(logfile,"At line no %d : type_specifier : INT\n\n",yylineno);
                        fprintf(logfile,"int \n\n");
                        $$->set_name("int ");
                      }
 		| FLOAT { $$ = new symbolInfo();
                          fprintf(logfile,"At line no %d : type_specifier : FLOAT\n\n",yylineno);
                          fprintf(logfile,"float \n\n");
                          $$->set_name("float ");
                        }
 		| VOID { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : type_specifier : VOID\n\n",yylineno);
                         fprintf(logfile,"void \n\n");
                         $$->set_name("void ");
                       }
 		;
 		
declaration_list : declaration_list COMMA ID { $$ = new symbolInfo();
                                               fprintf(logfile,"At line no %d : declaration_list : declaration_list COMMA ID\n\n",yylineno);
			                       fprintf(logfile,"%s,%s\n\n",$1->get_name().c_str(),$3->get_name().c_str());
                                               symbolInfo* s = new symbolInfo();
                                               s->set_name($3->get_name());
                                               s->set_type("ID"); 
                                               declarations.push_back(s); 
			                       $$->set_name($1->get_name() + "," + $3->get_name());
                                             }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD { $$ = new symbolInfo();
                                                                        fprintf(logfile,"At line no %d : declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",yylineno);
			                                                fprintf(logfile,"%s,%s[%s]\n\n",$1->get_name().c_str(),$3->get_name().c_str(),$5->get_name().c_str());
                                                                        symbolInfo* s = new symbolInfo();
                                                                        s->set_name($3->get_name());
                                                                        //s->set_type("ID_ARRAY");
                                                                        s->set_type("ID" + $5->get_name()); 
                                                                        declarations.push_back(s); 
			                                                $$->set_name($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]");
                                                                      }
 		  | ID { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : declaration_list : ID\n\n",yylineno);
	                 fprintf(logfile,"%s\n\n",$1->get_name().c_str());
                         symbolInfo* s = new symbolInfo();
                         s->set_name($1->get_name());
                         s->set_type("ID"); 
                         declarations.push_back(s); 
                         $$->set_name($1->get_name());
                       }
 		  | ID LTHIRD CONST_INT RTHIRD { $$ = new symbolInfo();
                                                 fprintf(logfile,"At line no %d : declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n",yylineno);
			                         fprintf(logfile,"%s[%s]\n\n",$1->get_name().c_str(),$3->get_name().c_str());
                                                 symbolInfo* s = new symbolInfo();
                                                 s->set_name($1->get_name());
                                                 //s->set_type("ID_ARRAY");
                                                 s->set_type("ID" + $3->get_name()); 
                                                 declarations.push_back(s); 
			                         $$->set_name($1->get_name() + "[" + $3->get_name() + "]");
                                                 //cout<<123<<endl;
                                               }
 		  ;
 		  
statements : statement { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : statements : statement\n\n",yylineno);
	                 fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                         $$->set_name($1->get_name());
                         $$->set_code($1->get_code());
                       }
	   | statements statement { $$ = new symbolInfo();
                                    fprintf(logfile,"At line no %d : statements : statements statement \n\n",yylineno);
			            fprintf(logfile,"%s\n%s\n\n",$1->get_name().c_str(),$2->get_name().c_str());
			            $$->set_name($1->get_name() + "\n" + $2->get_name());
                                    $$->set_code($1->get_code() + $2->get_code()); 
                                  }
	   ;
	   
statement : var_declaration { $$ = new symbolInfo();
                              fprintf(logfile,"At line no %d : statement : var_declaration\n\n",yylineno);
	                      fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                              $$->set_name($1->get_name());
                            }
	  | expression_statement { $$ = new symbolInfo();
                                   fprintf(logfile,"At line no %d : statement : expression_statement\n\n",yylineno);
	                           fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                                   $$->set_name($1->get_name());
                                   $$->set_code($1->get_code());
                                 }
	  | compound_statement { $$ = new symbolInfo();
                                 fprintf(logfile,"At line no %d : statement : compound_statement\n\n",yylineno);
	                         fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                                 $$->set_name($1->get_name());
                                 $$->set_code($1->get_code());
                               }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement { $$ = new symbolInfo(); 
                                                                                               fprintf(logfile,"At line no %d : statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",yylineno);
					                                                       fprintf(logfile,"for(%s %s %s)\n%s\n\n",$3->get_name().c_str(),$4->get_name().c_str(),$5->get_name().c_str(),$7->get_name().c_str());
                                                                                               $$->set_name("for(" + $3->get_name() + $4->get_name() + $5->get_name() + ")\n" + $7->get_name());
                                                                                               if($3->get_realtype() == "void "){
												   error_count++;
												   fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno); 
											       }
                                                                                               else{
                                                                                                   string codes = $3->get_code();
												   char *label1 = newLabel();
												   char *label2 = newLabel();
												   codes += string(label1) + ":\n";
											           codes += $4->get_code();
												   codes += "\tMOV AX," + $4->get_id_value() + "\n";
											           codes += "\tCMP AX,0\n";
												   codes += "\tJE " + string(label2) + "\n";
												   codes += $7->get_code();
												   codes += $5->get_code();
												   codes += "\tJMP " + string(label1) + "\n";
												   codes += string(label2) + ":\n";
												   $$->set_code(codes);
                                                                                               }
                                                                                             }
	  | IF LPAREN expression RPAREN statement %prec DUMMY { $$ = new symbolInfo();
                                                    fprintf(logfile,"At line no %d : statement : IF LPAREN expression RPAREN statement\n\n",yylineno);
			                            fprintf(logfile,"if(%s)\n%s\n\n",$3->get_name().c_str(),$5->get_name().c_str()); 
			                            $$->set_name("if(" + $3->get_name() + ")\n" + $5->get_name());
                                                    if($3->get_realtype()=="void "){
							error_count++;
						        fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno); 
						    }
                                                    else{
                                                        string codes = $3->get_code();
							char *label1 = newLabel();
						        codes += "\tMOV AX," + $3->get_id_value() + "\n";
						        codes += "\tCMP AX,0\n";
							codes += "\tJE " + string(label1) + "\n";
							codes += $5->get_code();
							codes += string(label1) + ":\n";
							$$->set_code(codes);
                                                    }
                                                  }
	  | IF LPAREN expression RPAREN statement ELSE statement { $$ = new symbolInfo();
                                                                   fprintf(logfile,"At line no %d : statement : IF LPAREN expression RPAREN statement ELSE statement\n\n",yylineno);
			                                           fprintf(logfile,"if(%s)\n%s\nelse\n%s\n\n",$3->get_name().c_str(),$5->get_name().c_str(),$7->get_name().c_str()); 
			                                           $$->set_name("if(" + $3->get_name() + ")\n" + $5->get_name() + "\n" + "else\n" + $7->get_name());
                                                                   if($3->get_realtype()=="void "){
							               error_count++;
						                       fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno); 
						                   }
                                                                   else{
                                                                       string codes = $3->get_code();
								       char *label1 = newLabel();
							               char *label2 = newLabel();
								       codes += "\tMOV AX," + $3->get_id_value()+"\n";
								       codes += "\tCMP AX,0\n";
								       codes += "\tJE " + string(label1) + "\n";
								       codes += $5->get_code();
								       codes += "\tJMP " + string(label2) + "\n";
								       codes += string(label1) + ":\n";
						                       codes += $7->get_code();
								       codes += string(label2) + ":\n";
								       $$->set_code(codes);
                                                                   }
                                                                 }
	  | WHILE LPAREN expression RPAREN statement { $$ = new symbolInfo();
                                                       fprintf(logfile,"At line no %d : statement : WHILE LPAREN expression RPAREN statement\n\n",yylineno);
			                               fprintf(logfile,"while(%s)\n%s\n\n",$3->get_name().c_str(),$5->get_name().c_str()); 
			                               $$->set_name("while(" + $3->get_name() + ")\n" + $5->get_name());
                                                       if($3->get_realtype()=="void "){
							   error_count++;
						           fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno); 
						       }
                                                       else{
                                                           string codes = "";
							   char *label1 = newLabel();
							   char *label2 = newLabel();
							   codes += string(label1) + ":\n";
							   codes += $3->get_code();
							   codes += "\tMOV AX," + $3->get_id_value() + "\n";
							   codes += "\tCMP AX,0\n";
							   codes += "\tJE " + string(label2) + "\n";
							   codes += $5->get_code();
							   codes += "\tJMP " + string(label1) + "\n";
							   codes += string(label2) + ":\n";
							   $$->set_code(codes);
                                                       }
                                                     }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON { $$ = new symbolInfo();
                                                 fprintf(logfile,"At line no %d : statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",yylineno);
			                         fprintf(logfile,"println(%s);\n\n",$3->get_name().c_str()); 
			                         $$->set_name("println(" + $3->get_name() + ");");
                                                 string codes = "";
						 if(st.look_up_id($3->get_name()) == -1){
						     error_count++;
						     fprintf(error,"Error at line no %d :  Undeclared Variable: %s \n\n",yylineno,$3->get_name().c_str());
						 }
						 else{
						     codes += "\tMOV AX," + $3->get_name() + int_to_string(st.look_up_id($3->get_name()));
				                     codes += "\n\tCALL OUTDEC\n";
						 }
                                                 $$->set_code(codes);
                                               }
          | PRINTLN LPAREN ID RPAREN %prec DUMMY2 { $$ = new symbolInfo();
                                                 fprintf(logfile,"At line no %d : statement : PRINTLN LPAREN ID RPAREN \n\n",yylineno);
			                         fprintf(logfile,"println(%s)\n\n",$3->get_name().c_str()); 
			                         $$->set_name("println(" + $3->get_name() + ")");
                                                 error_count++;
                                                 fprintf(error,"Error at line no %d : Expected Semicolon \n\n",yylineno);
                                                 
                                               }
	  | RETURN expression SEMICOLON { $$ = new symbolInfo();
                                          fprintf(logfile,"At line no %d : statement : RETURN expression SEMICOLON\n\n",yylineno);
	                                  fprintf(logfile,"return %s;\n\n",$2->get_name().c_str()); 
                                          $$->set_name("return " + $2->get_name() + ";");
                                          if($2->get_realtype()=="void "){
					      error_count++;
					      fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
                                              //$$->set_realtype("int"); 
				          }
                                          else{
                                              string codes = $2->get_code();
					      codes += "\tMOV AX," + $2->get_id_value() + "\n";
					      codes += "\tMOV " + function_return + "_return,AX\n";
					      codes += "\tJMP LReturn" + function_return + "\n";
				              $$->set_code(codes);
                                          }
                                        }
          /*| RETURN expression %prec DUMMY2 { $$ = new symbolInfo();
                                          fprintf(logfile,"At line no %d : statement : RETURN expression \n\n",yylineno);
	                                  fprintf(logfile,"return %s\n\n",$2->get_name().c_str()); 
                                          $$->set_name("return " + $2->get_name());
                                          if($2->get_realtype()=="void "){
					      error_count++;
					      fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
                                              //$$->set_realtype("int"); 
				          }
                                          error_count++;
                                          fprintf(error,"Error at line no %d : Expected Semicolon \n\n",yylineno);
                                        }*/
	  ;
	  
expression_statement 	: SEMICOLON { $$ = new symbolInfo();
                                      fprintf(logfile,"At line no %d : expression_statement : SEMICOLON\n\n",yylineno);
	                              fprintf(logfile,";\n\n"); 
                                      $$->set_name(";");
                                    }			
			| expression SEMICOLON { $$ = new symbolInfo();
                                                 fprintf(logfile,"At line no %d : expression_statement : expression SEMICOLON\n\n",yylineno);
	                                         fprintf(logfile,"%s;\n\n",$1->get_name().c_str()); 
                                                 $$->set_name($1->get_name() + ";");
                                                 $$->set_code($1->get_code());
			                         $$->set_id_value($1->get_id_value());
                                                 //$$->set_realtype($1->get_realtype());
                                               }
                        /*| expression %prec DUMMY2 { $$ = new symbolInfo();
                                                 fprintf(logfile,"At line no %d : expression_statement : expression \n\n",yylineno);
	                                         fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                                                 $$->set_name($1->get_name());
                                                 error_count++;
                                                 fprintf(error,"Error at line no %d : Expected Semicolon \n\n",yylineno);
                                                 //$$->set_realtype($1->get_realtype());
                                               }*/
			;
	  
variable : ID { $$ = new symbolInfo();
                fprintf(logfile,"At line no %d : variable : ID\n\n",yylineno);
	        fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                $$->set_name($1->get_name());
                $$->set_type("notarray");
                if(st.look_up($1->get_name()) == 0){
		     error_count++;
		     fprintf(error,"Error at line no %d : Undeclared Variable: %s \n\n",line_count,$1->get_name().c_str());
		}
	        else if(st.look_up($1->get_name())->get_realtype() == "int array" || st.look_up($1->get_name())->get_realtype() == "float array"){
		     error_count++;
		     fprintf(error,"Error at line no %d : Array %s not expected here \n\n",line_count,$1->get_name().c_str());
	        }
		if(st.look_up($1->get_name()) != 0){
		     $$->set_realtype(st.look_up($1->get_name())->get_realtype());
                     //cout<<st.look_up_id($1->get_name())<<endl;
                     $$->set_id_value($1->get_name() + int_to_string(st.look_up_id($1->get_name())));
                     //cout<<$$->get_id_value()<<endl; 
		}
              } 		
	 | ID LTHIRD expression RTHIRD { $$ = new symbolInfo(); 
                                         fprintf(logfile,"At line no %d : variable : ID LTHIRD expression RTHIRD\n\n",yylineno);
					 fprintf(logfile,"%s[%s]\n\n",$1->get_name().c_str(),$3->get_name().c_str());
                                         $$->set_name($1->get_name() + "[" + $3->get_name() + "]");
                                         $$->set_type("array");
                                         if(st.look_up($1->get_name()) == 0){
						error_count++;
						fprintf(error,"Error at line no %d : Undeclared Variable: %s \n\n",yylineno,$1->get_name().c_str());
					 }
					 if($3->get_realtype() == "float " || $3->get_realtype() == "void "){
				             error_count++;
					     fprintf(error,"Error at line no %d : Non-integer Array Index  \n\n",yylineno);
					 }
					 if(st.look_up($1->get_name())!=0){
					     if(st.look_up($1->get_name())->get_realtype() != "int array" && st.look_up($1->get_name())->get_realtype() != "float array"){
						  error_count++;
						  fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);	
					     }
					     if(st.look_up($1->get_name())->get_realtype() == "int array"){
                                                  $1->set_realtype("int ");
					     }
					     if(st.look_up($1->get_name())->get_realtype() == "float array"){
						  $1->set_realtype("float ");
					     }
					     $$->set_realtype($1->get_realtype());
                                             string codes = $3->get_code();
					     codes += "\tMOV BX," + $3->get_id_value() + "\n";
					     codes += "\tADD BX,BX\n";
					     $$->set_id_value($1->get_name() + int_to_string(st.look_up_id($1->get_name())));
					     $$->set_code(codes); 					
					 }
                                       }
	 ;
	 
expression : logic_expression { $$ = new symbolInfo();
                                fprintf(logfile,"At line no %d : expression : logic_expression\n\n",yylineno);
			        fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			        $$->set_name($1->get_name());
                                $$->set_realtype($1->get_realtype());
                                $$->set_code($1->get_code());
			        $$->set_id_value($1->get_id_value());
                              }	
	   | variable ASSIGNOP logic_expression { $$ = new symbolInfo();
                                                  fprintf(logfile,"At line no %d : expression : variable ASSIGNOP logic_expression\n\n",yylineno);
			                          fprintf(logfile,"%s=%s\n\n",$1->get_name().c_str(),$3->get_name().c_str()); 
			                          $$->set_name($1->get_name() + "=" + $3->get_name());
                                                  if($3->get_realtype() == "void "){
						      error_count++;
						      fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
						      $$->set_realtype("int "); 
						  }
                                                  //else if(st.look_up($1->get_name()) != 0){
                                                      //cout<<547694796<<endl;
						      if($1->get_realtype() != $3->get_realtype()){
						           error_count++;
						           fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
						      }
                                                      else{
                                                           string codes = $1->get_code() + $3->get_code();
							   codes += "\tMOV AX," + $3->get_id_value() + "\n";
							   if($1->get_type() == "notarray"){			
							       codes += "\tMOV " + $1->get_id_value() + ",AX\n";
                                                           }
							   else{
                                                               codes += "\tMOV " + $1->get_id_value() + "[BX],AX\n";
							   }
							   $$->set_code(codes);
                                                           $$->set_id_value($1->get_id_value());
                                                      }
					          //}
                                                  //cout<<$$->get_code()<<endl;
                                                  //cout<<$1->get_name()<<endl;
                                                  /*if(st.look_up($1->get_name()) == 0)
                                                      cout<<765<<endl;*/
						  $$->set_realtype($1->get_realtype());
                                                }	
	   ;
			
logic_expression : rel_expression { $$ = new symbolInfo();
                                    fprintf(logfile,"At line no %d : logic_expression : rel_expression\n\n",yylineno);
			            fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			            $$->set_name($1->get_name());
                                    $$->set_realtype($1->get_realtype());
                                    $$->set_code($1->get_code());
			            $$->set_id_value($1->get_id_value());
                                  }	
		 | rel_expression LOGICOP rel_expression { $$ = new symbolInfo();
                                                           fprintf(logfile,"At line no %d : logic_expression : rel_expression LOGICOP rel_expression\n\n",yylineno);
			                                   fprintf(logfile,"%s%s%s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$3->get_name().c_str()); 
			                                   $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
                                                           if($1->get_realtype() == "void " || $3->get_realtype() == "void "){
				                               error_count++;
					                       fprintf(error,"Error at line no %d : Invalid Operand Type \n\n",yylineno);
                                                           }
                                                           string codes = $1->get_code() + $3->get_code();
							   char *label1 = newLabel();
							   char *label2 = newLabel();
							   char *label3 = newLabel();
							   char *temp = newTemp();
                                                           if($2->get_name() == "||"){
							       codes += "\tMOV AX," + $1->get_id_value() + "\n";
							       codes += "\tCMP AX,0\n";
							       codes += "\tJNE " + string(label2) + "\n";
							       codes += "\tMOV AX," + $3->get_id_value() + "\n";
							       codes += "\tCMP AX,0\n";
							       codes += "\tJNE " + string(label2) + "\n";
							       codes += string(label1)+":\n";
							       codes += "\tMOV " + string(temp) + ",0\n";
							       codes += "\tJMP " + string(label3) + "\n";
							       codes += string(label2) + ":\n";
							       codes += "\tMOV " + string(temp) + ",1\n";
							       codes += string(label3) + ":\n";
                                                           }
							   else{
							       codes += "\tMOV AX," + $1->get_id_value() + "\n";
							       codes += "\tCMP AX,0\n";
							       codes += "\tJE " + string(label2) + "\n";
							       codes += "\tMOV AX," + $3->get_id_value() + "\n";
							       codes += "\tCMP AX,0\n";
							       codes += "\tJE "+string(label2)+"\n";
							       codes += string(label1) + ":\n";
							       codes += "\tMOV " + string(temp) + ",1\n";
							       codes += "\tJMP " + string(label3) + "\n";
							       codes += string(label2) + ":\n";
							       codes += "\tMOV " + string(temp) + ",0\n";
							       codes += string(label3) + ":\n";
			                                   }
							   $$->set_code(codes);
							   $$->set_id_value(temp);
							   variables.push_back(temp);
                                                           $$->set_realtype("int ");
                                                         } 	
		 ;
			
rel_expression	: simple_expression { $$ = new symbolInfo();
                                      fprintf(logfile,"At line no %d : rel_expression : simple_expression\n\n",yylineno);
			              fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			              $$->set_name($1->get_name());
                                      $$->set_realtype($1->get_realtype());
                                      $$->set_code($1->get_code());
			              $$->set_id_value($1->get_id_value());
                                    } 
		| simple_expression RELOP simple_expression { $$ = new symbolInfo();
                                                              fprintf(logfile,"At line no %d : rel_expression : simple_expression RELOP simple_expression\n\n",yylineno);
			                                      fprintf(logfile,"%s%s%s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$3->get_name().c_str()); 
			                                      $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
                                                              if($1->get_realtype() == "void " || $3->get_realtype() == "void "){
				                                  error_count++;
					                          fprintf(error,"Error at line no %d : Invalid Operand Type \n\n",yylineno);
                                                              }
                                                              else{
                                                                  string codes = $1->get_code() + $3->get_code();
								  char *temp = newTemp();
								  char *label1 = newLabel();
								  char *label2 = newLabel();
								  codes += "\tMOV AX," + $1->get_id_value() + "\n";
								  codes += "\tCMP AX," + $3->get_id_value() + "\n";
								  if($2->get_name() == "<"){
								      codes += "\tJL " + string(label1) + "\n";
                                                                  }
								  else if($2->get_name() == ">"){
								      codes += "\tJG " + string(label1) + "\n";
                                                                  }
								  else if($2->get_name() == "<="){
								      codes += "\tJLE " + string(label1) + "\n";
 					                          }
								  else if($2->get_name() == ">="){
								      codes += "\tJGE " + string(label1) + "\n";
								  }
								  else if($2->get_name() == "=="){
								      codes += "\tJE " + string(label1) + "\n";
								  }
								  else if($2->get_name() == "!="){
								      codes += "\tJNE " + string(label1) + "\n";
								  }
								  codes += "\tMOV " + string(temp) + ",0\n";
								  codes += "\tJMP " + string(label2) + "\n";
								  codes += string(label1) + ":\n";
								  codes += "\tMOV " + string(temp) + ",1\n";
								  codes += string(label2)+":\n";
								  $$->set_code(codes);
								  $$->set_id_value(temp);
                                                                  variables.push_back(temp);
                                                              }
                                                              $$->set_realtype("int ");
                                                            }	
		;
				
simple_expression : term { $$ = new symbolInfo();
                           fprintf(logfile,"At line no %d : simple_expression : term\n\n",yylineno);
			   fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			   $$->set_name($1->get_name());
                           $$->set_realtype($1->get_realtype());
                           $$->set_code($1->get_code());
			   $$->set_id_value($1->get_id_value());
                         } 
		  | simple_expression ADDOP term { $$ = new symbolInfo();
                                                   fprintf(logfile,"At line no %d : simple_expression : simple_expression ADDOP term\n\n",yylineno);
			                           fprintf(logfile,"%s%s%s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$3->get_name().c_str()); 
			                           $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
                                                   if($1->get_realtype() == "void " || $3->get_realtype() == "void "){
				                       error_count++;
					               fprintf(error,"Error at line no %d : Invalid Operand Type \n\n",yylineno);
				                       $$->set_realtype("int ");
                                                   }
                                                   else{
					               if($1->get_realtype() == "int " && $3->get_realtype() == "int "){
					                   $$->set_realtype("int ");
                                                       }
                                                       else 
				                           $$->set_realtype("float ");
                                                       if($2->get_name() == "+"){
                                                           string codes = $1->get_code() + $3->get_code();
                                                           char *temp = newTemp();
					                   codes += "\tMOV AX," + $1->get_id_value() + "\n";
                                                           codes += "\tADD AX," + $3->get_id_value() + "\n";
					                   codes += "\tMOV " + string(temp) + ",AX\n";
					                   $$->set_code(codes);
					                   $$->set_id_value(temp);
					                   variables.push_back(temp);
                                                       }
                                                       else{
                                                           string codes = $1->get_code() + $3->get_code();
					                   char *temp = newTemp();
			                                   codes += "\tMOV AX," + $1->get_id_value() + "\n";
					                   codes += "\t AX," + $3->get_id_value() + "\n";
					                   codes += "\tMOV " + string(temp) + ",AX\n";
					                   $$->set_code(codes);
					                   $$->set_id_value(temp);
					                   variables.push_back(temp);
                                                       }  
				                   }
                                                 } 
		  ;
					
term :	unary_expression { $$ = new symbolInfo();
                           fprintf(logfile,"At line no %d : term : unary_expression\n\n",yylineno);
			   fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			   $$->set_name($1->get_name());
                           $$->set_realtype($1->get_realtype());
                           $$->set_code($1->get_code());
			   $$->set_id_value($1->get_id_value());
                         }
     |  term MULOP unary_expression { $$ = new symbolInfo();
                                      fprintf(logfile,"At line no %d : term : term MULOP unary_expression\n\n",yylineno);
			              fprintf(logfile,"%s%s%s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$3->get_name().c_str()); 
			              $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
                                      if($1->get_realtype() == "void " || $3->get_realtype() == "void "){
				          error_count++;
					  fprintf(error,"Error at line no %d : Invalid Operand Type \n\n",yylineno);
				          $$->set_realtype("int ");
                                      }
                                      else if($2->get_name() == "%"){
					  if($1->get_realtype() != "int " || $3->get_realtype() != "int "){
					      error_count++;
					      fprintf(error,"Error at Line No.%d: Need Integer operand on modulus operator  \n\n",yylineno);
                                          } 
				          $$->set_realtype("int ");
                                          string codes = $1->get_code() + $3->get_code();
					  char *temp = newTemp();
					  codes += "\tMOV AX," + $1->get_id_value() + "\n";
					  codes += "\tMOV BX," + $3->get_id_value() + "\n";
					  codes += "\tMOV DX,0\n";
					  codes += "\tDIV BX\n";
					  codes += "\tMOV " + string(temp) + ",DX\n";
			                  $$->set_code(codes);
					  $$->set_id_value(temp);
					  variables.push_back(temp); 
				      }
                                      else{
					  if($1->get_realtype() == "int " && $3->get_realtype() == "int "){
					      $$->set_realtype("int ");
                                          }
                                          else 
				              $$->set_realtype("float ");
                                          if($2->get_name() == "/"){
                                              string codes = $1->get_code() + $3->get_code();
					      char *temp = newTemp();
					      codes += "\tMOV AX," + $1->get_id_value() + "\n";
					      codes += "\tMOV BX," + $3->get_id_value() + "\n";
                                              codes += "\tDIV BX\n";
					      codes += "\tMOV " + string(temp) + ",AX\n";
					      $$->set_code(codes);
					      $$->set_id_value(temp);
					      variables.push_back(temp);
                                          }
                                          else{
                                              string codes = $1->get_code() + $3->get_code();
					      char *temp = newTemp();
			                      codes += "\tMOV AX," + $1->get_id_value() + "\n";
					      codes += "\tMOV BX," + $3->get_id_value() + "\n";
					      codes += "\tMUL BX\n";
					      codes += "\tMOV " + string(temp) + ",AX\n";
					      $$->set_code(codes);
					      $$->set_id_value(temp);
					      variables.push_back(temp);
                                          } 
				      }
                                    }
     ;

unary_expression : ADDOP unary_expression { $$ = new symbolInfo();
                                            fprintf(logfile,"At line no %d : unary_expression : ADDOP unary_expression\n\n",yylineno);
		 	                    fprintf(logfile,"%s%s\n\n",$1->get_name().c_str(),$2->get_name().c_str());  
			                    $$->set_name($1->get_name() + $2->get_name());
                                            if($2->get_realtype() == "void "){
					        error_count++;
					        fprintf(error,"Error at line no %d :  Type Mismatch \n\n",yylineno);
					        $$->set_realtype("int "); 
				            }
                                            else{ 
				                $$->set_realtype($2->get_realtype());
                                                string codes = $2->get_code();
						if($1->get_name() == "-"){
						     codes += "\tMOV AX," + $2->get_id_value() + "\n";
						     codes += "\tNEG AX\n";
						     codes += "\tMOV " + $2->get_id_value() + ",AX\n";
						}
						$$->set_code(codes);
						$$->set_id_value($2->get_id_value());
                                            }
                                          }  
		 | NOT unary_expression { $$ = new symbolInfo();
                                          fprintf(logfile,"At line no %d : unary_expression : NOT unary_expression\n\n",yylineno);
		 	                  fprintf(logfile,"!%s\n\n",$1->get_name().c_str());  
			                  $$->set_name("!" + $1->get_name());
                                          if($2->get_realtype() == "void "){
					        error_count++;
					        fprintf(error,"Error at line no %d :  Type Mismatch \n\n",yylineno);
					        $$->set_realtype("int "); 
				          }
                                          else{ 
				                $$->set_realtype($2->get_realtype());
                                                string codes = $2->get_code();
					        codes += "\tMOV AX," + $2->get_id_value() + "\n";
					        codes += "\tNOT AX\n";
					        codes += "\tMOV " + $2->get_id_value() + ",AX\n";
                                                $$->set_code(codes);
					        $$->set_id_value($2->get_id_value());
                                          }
                                        } 
		 | factor { $$ = new symbolInfo();
                            fprintf(logfile,"At line no %d : unary_expression : factor\n\n",yylineno);
		 	    fprintf(logfile,"%s\n\n",$1->get_name().c_str());  
			    $$->set_name($1->get_name());
                            $$->set_realtype($1->get_realtype());
                            $$->set_code($1->get_code());
			    $$->set_id_value($1->get_id_value()); 
                          } 
		 ;
	
factor	: variable { $$ = new symbolInfo();
                     fprintf(logfile,"At line no %d : factor : variable\n\n",yylineno);
	             fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
		     $$->set_name($1->get_name());
                     $$->set_realtype($1->get_realtype());
                     string codes = $1->get_code();
		     if($1->get_type() == "array"){
			 char *temp = newTemp();
			 codes += "\tMOV AX," + $1->get_id_value() + "[BX]\n";
			 codes += "\tMOV " + string(temp) + ",AX\n";
			 variables.push_back(temp);
			 $$->set_id_value(temp);
		     }
		     else{
			 $$->set_id_value($1->get_id_value());
                         //cout<<899<<endl;
		     }
                     $$->set_code(codes);
                   }
	| ID LPAREN argument_list RPAREN { $$ = new symbolInfo(); 
                                           fprintf(logfile,"At line no %d : factor : ID LPAREN argument_list RPAREN\n\n",yylineno);
					   fprintf(logfile,"%s(%s)\n\n",$1->get_name().c_str(),$3->get_name().c_str());
                                           $$->set_name($1->get_name() + "(" + $3->get_name() + ")");
                                           symbolInfo* s = new symbolInfo();
                                           s = st.look_up($1->get_name());
					   if(s == 0){
					       error_count++;
					       fprintf(error,"Error at line no %d : Undeclared Function \n\n",yylineno);
					       $$->set_realtype("int "); 
					   }
					   else if(s->function == 0){
					       error_count++;
					       fprintf(error,"Error at line no %d : Not A Function \n\n",yylineno);
					       $$->set_realtype("int "); 
					   }
					   else{
					       if(s->function->get_defined() == 0){
						   error_count++;
						   fprintf(error,"Error at line no %d : Undefined Function \n\n",yylineno);
				               }
                                               int number = s->function->get_number_of_parameters();
					       $$->set_realtype(s->function->get_return_type());
					       if(number != argumentss.size()){
						   error_count++;
						   fprintf(error,"Error at line no %d : Invalid number of arguments \n\n",yylineno);
                                               }
					       else{
						   vector<string>parameter_list = s->function->get_parameter_list();
						   vector<string>parameter_type = s->function->get_parameter_type_list();
                                                   string codes = $3->get_code();
                                                   //cout<<argumentss.size()<<endl;
						   for(int i=0 ; i<argumentss.size() ; i++){
                                                       codes += "\tMOV AX," + argumentss[i]->get_id_value() + "\n";
                                                       //cout<<argumentss[i]->get_id_value<<endl;
                                                       //cout<<897<<endl;
						       codes += "\tMOV "+ parameter_list[i] + ",AX\n";
						       if(argumentss[i]->get_realtype() != parameter_type[i]){
							   error_count++;
							   fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
							   break;
						       }
						   }
                                                   //string codes = $3->get_code();
                                                   codes += "\tCALL " + $1->get_name() + "\n";
						   codes += "\tMOV AX," + $1->get_name() + "_return\n";
						   char *temp = newTemp();
						   codes += "\tMOV " + string(temp) + ",AX\n";
						   $$->set_code(codes);
						   $$->set_id_value(temp);
						   variables.push_back(temp);
					       }
					   }
					   argumentss.clear();
                                         }
	| LPAREN expression RPAREN { $$ = new symbolInfo();
                                     fprintf(logfile,"At line no %d : factor : LPAREN expression RPAREN\n\n",yylineno);
			             fprintf(logfile,"(%s)\n\n",$2->get_name().c_str()); 
			             $$->set_name("(" + $2->get_name() + ")");
                                     $$->set_realtype($2->get_realtype());
                                     $$->set_code($2->get_code());
				     $$->set_id_value($2->get_id_value());
                                   }
	| CONST_INT { $$ = new symbolInfo();
                      fprintf(logfile,"At line no %d : factor : CONST_INT\n\n",yylineno);
	              fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
		      $$->set_name($1->get_name());
                      $$->set_realtype("int ");
                      char *temp = newTemp();
		      string codes = "\tMOV " + string(temp) + "," + $1->get_name() + "\n";
		      $$->set_code(codes);
		      $$->set_id_value(string(temp));
		      variables.push_back(temp);
                    } 
	| CONST_FLOAT { $$ = new symbolInfo();
                        fprintf(logfile,"At line no %d : factor : CONST_FLOAT\n\n",yylineno);
			fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			$$->set_name($1->get_name());
                        $$->set_realtype("float ");
                        char *temp = newTemp();
			string codes = "\tMOV " + string(temp) + "," + $1->get_name() + "\n";
			$$->set_code(codes);
			$$->set_id_value(string(temp));
			variables.push_back(temp); 
                      }
	| variable INCOP { $$ = new symbolInfo();
                           fprintf(logfile,"At line no %d : factor : variable INCOP\n\n",yylineno);
			   fprintf(logfile,"%s++\n\n",$1->get_name().c_str()); 
			   $$->set_name($1->get_name() + "++");
                           $$->set_realtype($1->get_realtype());
                           char *temp = newTemp();
			   string codes = "";
			   if($1->get_type() == "array"){
			       codes += "\tMOV AX," + $1->get_id_value() + "[BX]\n";
			   }
			   else
			       codes += "\tMOV AX," + $1->get_id_value() + "\n";
			   codes += "\tMOV " + string(temp) + ",AX\n";
			   if($1->get_type() == "array"){
			       codes += "\tMOV AX," + $1->get_id_value() + "[BX]\n";
			       codes += "\tINC AX\n";
			       codes += "\tMOV " + $1->get_id_value() + "[BX],AX\n";
			   }
			   else
			       codes += "\tINC " + $1->get_id_value() + "\n";
		           variables.push_back(temp);
                           $$->set_code(codes); 
			   $$->set_id_value(temp); 
                         } 
	| variable DECOP { $$ = new symbolInfo();
                           fprintf(logfile,"At line no %d : factor : variable DECOP\n\n",yylineno);
			   fprintf(logfile,"%s--\n\n",$1->get_name().c_str()); 
			   $$->set_name($1->get_name() + "--"); 
                           $$->set_realtype($1->get_realtype());
                           char *temp = newTemp();
			   string codes = "";
			   if($1->get_type() == "array"){
			       codes += "\tMOV AX," + $1->get_id_value() + "[BX]\n";
			   }
			   else
			       codes += "\tMOV AX," + $1->get_id_value() + "\n";
			   codes += "\tMOV " + string(temp) + ",AX\n";
			   if($1->get_type() == "array"){
			       codes += "\tMOV AX," + $1->get_id_value() + "[BX]\n";
			       codes += "\tDEC AX\n";
			       codes += "\tMOV " + $1->get_id_value() + "[BX],AX\n";
			   }
			   else
			       codes += "\tDEC " + $1->get_id_value() + "\n";
		           variables.push_back(temp);
                           $$->set_code(codes); 
			   $$->set_id_value(temp);
                         }
	;
	
argument_list : arguments { $$ = new symbolInfo(); 
                            fprintf(logfile,"At line no %d : argument_list : arguments\n\n",yylineno);
			    fprintf(logfile,"%s\n\n",$1->get_name().c_str());
			    $$->set_name($1->get_name());
                            $$->set_code($1->get_code());
                          }
	      |        { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : argument_list : \n\n",yylineno);
                         $$->set_name("");
                       }
              ;
	
arguments : arguments COMMA logic_expression { $$ = new symbolInfo();
                                               fprintf(logfile,"At line no %d : arguments : arguments COMMA logic_expression \n\n",yylineno);
					       fprintf(logfile,"%s,%s\n\n",$1->get_name().c_str(),$3->get_name().c_str());
					       $$->set_name($1->get_name() + "," + $3->get_name());
                                               $$->set_code($1->get_code() + $3->get_code());
                                               //symbolInfo* s = new symbolInfo();
                                               //s->set_name($3->get_name());
                                               //s->set_type($3->get_type());
                                               //s->set_realtype($3->get_realtype()); 
                                               argumentss.push_back($3);
                                             }
	  | logic_expression { $$ = new symbolInfo();
		               fprintf(logfile,"At line no %d : arguments : logic_expression\n\n",yylineno);
		  	       fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
		  	       $$->set_name($1->get_name());
                               $$->set_code($1->get_code());
                               //symbolInfo* s = new symbolInfo();
                               //s->set_name($1->get_name());
                               //s->set_type($1->get_type());
                               //s->set_realtype($1->get_realtype()); 
                               argumentss.push_back($1);
                             }
	  ;
 

%%

bool check(string s1,string s2){
	 
	if(s1.size() != s2.size() || s1.size()<11) 
                return false;
        int j;
	for(j=0;j<s1.size();j++){
		if(s1[j]=='M') 
                       break;
	}
	if(j == s1.size()) 
                return false;
	 
	if(s1[j]!='M' || s1[j+1]!='O' || s1[j+2]!='V') 
                return false;

	for(j=0;j<s2.size();j++){
		if(s2[j] == 'M') 
                       break;
	}
	if(j == s2.size()) 
                return false;

	if(s2[j]!='M' || s2[j+1]!='O' || s2[j+2]!='V') 
                return false;

	string source1="" , dest1="";
	string source2="" , dest2="";
	int i;
	for(i=j+4;i<s1.size()-1;i++){
		if(s1[i]==' ' && source1.size()==0) 
                       continue;
		if(s1[i]==' ' || s1[i]==',') 
                       break;
		source1.push_back(s1[i]);
	}

	for(;i<s1.size()-1;i++){
	        if((s1[i]==' '||s1[i]==',') && dest1.size()==0) 
                       continue;
		if(s1[i]==' ') 
                       break;
		dest1.push_back(s1[i]);
	}

	for(i=j+4;i<s2.size()-1;i++){
		if(s2[i]==' ' && source2.size()==0) 
                       continue;
		if(s2[i]==' '|| s2[i]==',') 
                       break;
		source2.push_back(s2[i]);
	}

	for(;i<s2.size()-1;i++){
		if((s2[i]==' '||s2[i]==',') && dest2.size()==0) 
                      continue;
		if(s2[i]==' ') 
                      break;
		dest2.push_back(s2[i]);
	}

	if(dest1==source2 && dest2==source1)
                return true;
	return false;
 }

void optimization(FILE *assembly){
	FILE* optimized = fopen("optimized-Code.asm","w");
	char * line = NULL;
        size_t len = 0;
        ssize_t read;
	vector<string>v;
       
        while ((read = getline(&line, &len, assembly)) != -1) {
	         v.push_back(string(line));
        }

	int sz = v.size();
	int mark[sz];

	for(int i=0;i<sz;i++) 
		mark[i] = 1;
	for(int i=0;i<sz-1;i++){
		if(check(v[i],v[i+1])){
			mark[i+1]=0;
		}
	}
	for(int i=0;i<sz;i++){
		if(mark[i])
		        fprintf(optimized,"%s",v[i].c_str());
	}

	fclose(assembly);
	fclose(optimized);
        if (line)
                free(line);

}

int main(int argc,char *argv[])
{ 
        st.enter_scope(sc);

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		return 0;
	}
	yyin=fp;
	yyparse();

	fprintf(logfile,"Symbol Table : \n\n");
	st.print_all();
        //%define api.value.type{symbolInfo*}

	fprintf(logfile,"Total Lines : %d \n\n",yylineno-1);
	fprintf(logfile,"Total Errors : %d \n\n",error_count);
	fprintf(error,"Total Errors : %d \n\n",error_count);

	fclose(fp);
	fclose(logfile);
	fclose(error);

	return 0;
}
