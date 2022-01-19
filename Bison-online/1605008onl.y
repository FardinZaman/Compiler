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

vector<symbolInfo*>parameters;
vector<symbolInfo*>declarations;
vector<symbolInfo*>argumentss;

void yyerror(const char *s)
{
	//write your code
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

%nonassoc DUMMY3
%nonassoc DUMMY4


%token <symbolinfo>ID 

%type <symbolinfo> start program unit func_declaration func_definition parameter_list compound_statement declaration_list statements var_declaration type_specifier
%type <symbolinfo> statement expression expression_statement variable logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

%%

start : program { $$ = new symbolInfo();
                  fprintf(logfile,"At line no %d : start : program\n\n",yylineno);
	          fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                  $$->set_name($1->get_name());
                }
	;

program : program unit { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : program : program unit \n\n",yylineno);
			 fprintf(logfile,"%s %s\n\n",$1->get_name().c_str(),$2->get_name().c_str());
			 $$->set_name($1->get_name() + $2->get_name());
                       } 
	| unit { $$ = new symbolInfo();
                 fprintf(logfile,"At line no %d : program : unit\n\n",yylineno);
	         fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                 $$->set_name($1->get_name());
               }
	;
	
unit : var_declaration { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : unit : var_declaration\n\n",yylineno);
	                 fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                         $$->set_name($1->get_name() + "\n");
                       }
     | func_declaration { $$ = new symbolInfo();
                          fprintf(logfile,"At line no %d : unit : func_declaration\n\n",yylineno);
	                  fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                          $$->set_name($1->get_name() + "\n");
                        }
     | func_definition { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : unit : func_definition\n\n",yylineno);
	                 fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                         $$->set_name($1->get_name() + "\n");
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
						                           s->function->add_parameter(parameters[i]->get_name(),parameters[i]->get_realtype());
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
                                                                 }compound_statement { $$ = new symbolInfo();
                                                                                       fprintf(logfile,"At line no %d : func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",yylineno);                                                     fprintf(logfile,"%s %s(%s) %s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$4->get_name().c_str(),$7->get_name().c_str());                
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
                                                                   
                                                  }compound_statement { $$ = new symbolInfo();
                                                                        fprintf(logfile,"At line no %d : func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n",yylineno);
			                                                fprintf(logfile,"%s %s() %s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$6->get_name().c_str()); 
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
                             for(int i=0;i<parameters.size();i++)
				  st.insert_symbol(parameters[i]->get_name(),"ID",parameters[i]->get_realtype());
		             parameters.clear();
                           } statements RCURL { $$ = new symbolInfo();
                                                fprintf(logfile,"At line no %d : compound_statement : LCURL statements RCURL\n\n",yylineno);
	                                        fprintf(logfile,"{\n%s\n}\n\n",$3->get_name().c_str()); 
                                                $$->set_name("{\n" + $3->get_name() + "\n" + "}");
                                                st.print_all();
                                                st.exit_scope();
                                              }
 		    | LCURL RCURL { scope_table* sct = new scope_table(7);
                                    st.enter_scope(sct);
                                    for(int i=0;i<parameters.size();i++)
				          st.insert_symbol(parameters[i]->get_name(),"ID",parameters[i]->get_realtype());
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
                                                                      else if(declarations[i]->get_type() == "ID_ARRAY"){
                                                                           declarations[i]->set_type("ID");
                                                                           st.insert_symbol(declarations[i]->get_name(),"ID",$1->get_name() + "array");
                                                                      }
                                                                      else
                                                                           st.insert_symbol(declarations[i]->get_name(),"ID",$1->get_name()); 
                                                                  }
                                                              }
                                                              declarations.clear();
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
                                                                        s->set_type("ID_ARRAY"); 
                                                                        declarations.push_back(s); 
			                                                $$->set_name($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]");
                                                                      }
                  | declaration_list COMMA ID ASSIGNOP logic_expression %prec DUMMY4 {$$ = new symbolInfo();
                                                  fprintf(logfile,"At line no %d : declaration_list : declaretion_list COMMA ID ASSIGNOP logic_expression\n\n",yylineno);
			                          fprintf(logfile,"%s,%s=%s\n\n",$1->get_name().c_str(),$3->get_name().c_str(),$5->get_name().c_str());
                                                  symbolInfo* s = new symbolInfo();
                                                  s->set_name($3->get_name());
                                                  s->set_type("ID"); 
                                                  declarations.push_back(s); 
			                          $$->set_name($1->get_name() + "," + $3->get_name() + "=" + $5->get_name());
                                                  if($5->get_realtype() == "void "){
						      error_count++;
						      fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
						      //$$->set_realtype("int "); 
						  }}
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
                                                 s->set_type("ID_ARRAY"); 
                                                 declarations.push_back(s); 
			                         $$->set_name($1->get_name() + "[" + $3->get_name() + "]");
                                               }
                  | ID ASSIGNOP logic_expression { $$ = new symbolInfo();
                                                  fprintf(logfile,"At line no %d : declaration_list : ID ASSIGNOP logic_expression\n\n",yylineno);
			                          fprintf(logfile,"%s=%s\n\n",$1->get_name().c_str(),$3->get_name().c_str());
                                                  symbolInfo* s = new symbolInfo();
                                                  s->set_name($1->get_name());
                                                  s->set_type("ID"); 
                                                  declarations.push_back(s); 
			                          $$->set_name($1->get_name() + "=" + $3->get_name());
                                                  if($3->get_realtype() == "void "){
						      error_count++;
						      fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
						      //$$->set_realtype("int "); 
						  }
                                                  /*else if(st.look_up($1->get_name()) != 0){
						      if(st.look_up($1->get_name())->get_realtype() != $3->get_realtype()){
						           error_count++;
						           fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
						      }
					          }*/
						  //$$->set_realtype($1->get_realtype());
                                                }
 		  ;
 		  
statements : statement { $$ = new symbolInfo();
                         fprintf(logfile,"At line no %d : statements : statement\n\n",yylineno);
	                 fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                         $$->set_name($1->get_name());
                       }
	   | statements statement { $$ = new symbolInfo();
                                    fprintf(logfile,"At line no %d : statements : statements statement \n\n",yylineno);
			            fprintf(logfile,"%s\n%s\n\n",$1->get_name().c_str(),$2->get_name().c_str());
			            $$->set_name($1->get_name() + "\n" + $2->get_name()); 
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
                                 }
	  | compound_statement { $$ = new symbolInfo();
                                 fprintf(logfile,"At line no %d : statement : compound_statement\n\n",yylineno);
	                         fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
                                 $$->set_name($1->get_name());
                               }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement { $$ = new symbolInfo(); 
                                                                                               fprintf(logfile,"At line no %d : statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",yylineno);
					                                                       fprintf(logfile,"for(%s %s %s)\n%s\n\n",$3->get_name().c_str(),$4->get_name().c_str(),$5->get_name().c_str(),$7->get_name().c_str());
                                                                                               $$->set_name("for(" + $3->get_name() + $4->get_name() + $5->get_name() + ")\n" + $7->get_name());
                                                                                               if($3->get_realtype() == "void "){
												   error_count++;
												   fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno); 
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
                                                  }
	  | IF LPAREN expression RPAREN statement ELSE statement { $$ = new symbolInfo();
                                                                   fprintf(logfile,"At line no %d : statement : IF LPAREN expression RPAREN statement ELSE statement\n\n",yylineno);
			                                           fprintf(logfile,"if(%s)\n%s\nelse\n%s\n\n",$3->get_name().c_str(),$5->get_name().c_str(),$7->get_name().c_str()); 
			                                           $$->set_name("if(" + $3->get_name() + ")\n" + $5->get_name() + "\n" + "else\n" + $7->get_name());
                                                                   if($3->get_realtype()=="void "){
							               error_count++;
						                       fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno); 
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
                                                     }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON { $$ = new symbolInfo();
                                                 fprintf(logfile,"At line no %d : statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",yylineno);
			                         fprintf(logfile,"println(%s);\n\n",$3->get_name().c_str()); 
			                         $$->set_name("println(" + $3->get_name() + ");");
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
		}
              } 		
	 | ID LTHIRD expression RTHIRD { $$ = new symbolInfo(); 
                                         fprintf(logfile,"At line no %d : variable : ID LTHIRD expression RTHIRD\n\n",yylineno);
					 fprintf(logfile,"%s[%s]\n\n",$1->get_name().c_str(),$3->get_name().c_str());
                                         $$->set_name($1->get_name() + "[" + $3->get_name() + "]");
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
					 }
                                       }
	 ;
	 
expression : logic_expression { $$ = new symbolInfo();
                                fprintf(logfile,"At line no %d : expression : logic_expression\n\n",yylineno);
			        fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			        $$->set_name($1->get_name());
                                $$->set_realtype($1->get_realtype());
                              }	
	   | variable ASSIGNOP logic_expression %prec DUMMY3 { $$ = new symbolInfo();
                                                  fprintf(logfile,"At line no %d : expression : variable ASSIGNOP logic_expression\n\n",yylineno);
			                          fprintf(logfile,"%s=%s\n\n",$1->get_name().c_str(),$3->get_name().c_str()); 
			                          $$->set_name($1->get_name() + "=" + $3->get_name());
                                                  if($3->get_realtype() == "void "){
						      error_count++;
						      fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
						      $$->set_realtype("int "); 
						  }
                                                  else if(st.look_up($1->get_name()) != 0){
						      if(st.look_up($1->get_name())->get_realtype() != $3->get_realtype()){
						           error_count++;
						           fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
						      }
					          }
						  $$->set_realtype($1->get_realtype());
                                                }	
	   ;
			
logic_expression : rel_expression { $$ = new symbolInfo();
                                    fprintf(logfile,"At line no %d : logic_expression : rel_expression\n\n",yylineno);
			            fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			            $$->set_name($1->get_name());
                                    $$->set_realtype($1->get_realtype());
                                  }	
		 | rel_expression LOGICOP rel_expression { $$ = new symbolInfo();
                                                           fprintf(logfile,"At line no %d : logic_expression : rel_expression LOGICOP rel_expression\n\n",yylineno);
			                                   fprintf(logfile,"%s%s%s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$3->get_name().c_str()); 
			                                   $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
                                                           if($1->get_realtype() == "void " || $3->get_realtype() == "void "){
				                               error_count++;
					                       fprintf(error,"Error at line no %d : Invalid Operand Type \n\n",yylineno);
                                                           }
                                                           $$->set_realtype("int ");
                                                         } 	
		 ;
			
rel_expression	: simple_expression { $$ = new symbolInfo();
                                      fprintf(logfile,"At line no %d : rel_expression : simple_expression\n\n",yylineno);
			              fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			              $$->set_name($1->get_name());
                                      $$->set_realtype($1->get_realtype());
                                    } 
		| simple_expression RELOP simple_expression { $$ = new symbolInfo();
                                                              fprintf(logfile,"At line no %d : rel_expression : simple_expression RELOP simple_expression\n\n",yylineno);
			                                      fprintf(logfile,"%s%s%s\n\n",$1->get_name().c_str(),$2->get_name().c_str(),$3->get_name().c_str()); 
			                                      $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
                                                              if($1->get_realtype() == "void " || $3->get_realtype() == "void "){
				                                  error_count++;
					                          fprintf(error,"Error at line no %d : Invalid Operand Type \n\n",yylineno);
                                                              }
                                                              $$->set_realtype("int ");
                                                            }	
		;
				
simple_expression : term { $$ = new symbolInfo();
                           fprintf(logfile,"At line no %d : simple_expression : term\n\n",yylineno);
			   fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			   $$->set_name($1->get_name());
                           $$->set_realtype($1->get_realtype());
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
				                   }
                                                 } 
		  ;
					
term :	unary_expression { $$ = new symbolInfo();
                           fprintf(logfile,"At line no %d : term : unary_expression\n\n",yylineno);
			   fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			   $$->set_name($1->get_name());
                           $$->set_realtype($1->get_realtype());
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
				      }
                                      else{
					  if($1->get_realtype() == "int " && $3->get_realtype() == "int "){
					      $$->set_realtype("int ");
                                          }
                                          else 
				              $$->set_realtype("float "); 
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
                                            else 
				                $$->set_realtype($2->get_realtype());
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
                                          else 
				                $$->set_realtype($2->get_realtype());
                                        } 
		 | factor { $$ = new symbolInfo();
                            fprintf(logfile,"At line no %d : unary_expression : factor\n\n",yylineno);
		 	    fprintf(logfile,"%s\n\n",$1->get_name().c_str());  
			    $$->set_name($1->get_name());
                            $$->set_realtype($1->get_realtype()); 
                          } 
		 ;
	
factor	: variable { $$ = new symbolInfo();
                     fprintf(logfile,"At line no %d : factor : variable\n\n",yylineno);
	             fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
		     $$->set_name($1->get_name());
                     $$->set_realtype($1->get_realtype());
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
						   for(int i=0 ; i<argumentss.size() ; i++){
						       if(argumentss[i]->get_realtype() != parameter_type[i]){
							   error_count++;
							   fprintf(error,"Error at line no %d : Type Mismatch \n\n",yylineno);
							   break;
						       }
						   }

					       }
					   }
					   argumentss.clear();
                                         }
	| LPAREN expression RPAREN { $$ = new symbolInfo();
                                     fprintf(logfile,"At line no %d : factor : LPAREN expression RPAREN\n\n",yylineno);
			             fprintf(logfile,"(%s)\n\n",$2->get_name().c_str()); 
			             $$->set_name("(" + $2->get_name() + ")");
                                     $$->set_realtype($2->get_realtype());
                                   }
	| CONST_INT { $$ = new symbolInfo();
                      fprintf(logfile,"At line no %d : factor : CONST_INT\n\n",yylineno);
	              fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
		      $$->set_name($1->get_name());
                      $$->set_realtype("int ");
                    } 
	| CONST_FLOAT { $$ = new symbolInfo();
                        fprintf(logfile,"At line no %d : factor : CONST_FLOAT\n\n",yylineno);
			fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
			$$->set_name($1->get_name());
                        $$->set_realtype("float "); 
                      }
	| variable INCOP { $$ = new symbolInfo();
                           fprintf(logfile,"At line no %d : factor : variable INCOP\n\n",yylineno);
			   fprintf(logfile,"%s++\n\n",$1->get_name().c_str()); 
			   $$->set_name($1->get_name() + "++");
                           $$->set_realtype($1->get_realtype()); 
                         } 
	| variable DECOP { $$ = new symbolInfo();
                           fprintf(logfile,"At line no %d : factor : variable DECOP\n\n",yylineno);
			   fprintf(logfile,"%s--\n\n",$1->get_name().c_str()); 
			   $$->set_name($1->get_name() + "--"); 
                           $$->set_realtype($1->get_realtype());
                         }
	;
	
argument_list : arguments { $$ = new symbolInfo(); 
                            fprintf(logfile,"At line no %d : argument_list : arguments\n\n",yylineno);
			    fprintf(logfile,"%s\n\n",$1->get_name().c_str());
			    $$->set_name($1->get_name());
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
                                               symbolInfo* s = new symbolInfo();
                                               s->set_name($3->get_name());
                                               s->set_type($3->get_type());
                                               s->set_realtype($3->get_realtype()); 
                                               argumentss.push_back(s);
                                             }
	  | logic_expression { $$ = new symbolInfo();
		               fprintf(logfile,"At line no %d : arguments : logic_expression\n\n",yylineno);
		  	       fprintf(logfile,"%s\n\n",$1->get_name().c_str()); 
		  	       $$->set_name($1->get_name());
                               symbolInfo* s = new symbolInfo();
                               s->set_name($1->get_name());
                               s->set_type($1->get_type());
                               s->set_realtype($1->get_realtype()); 
                               argumentss.push_back(s);
                             }
	  ;
 

%%


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

	fprintf(logfile,"Total Lines : %d \n\n",yylineno);
	fprintf(logfile,"Total Errors : %d \n\n",error_count);
	fprintf(error,"Total Errors : %d \n\n",error_count);

	fclose(fp);
	fclose(logfile);
	fclose(error);

	return 0;
}
