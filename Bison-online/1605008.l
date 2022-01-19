%option yylineno
%option noyywrap

%{

#include<iostream>
#include "1605008_symbol_table.h"
#include "y.tab.h"

using namespace std;

//extern "C" int yylex(void);

extern int line_count;
extern int error_count;

%}

NEWLINE		        \n
WHITESPACE 	        [ \t\f\r\v]+

LETTER 		        [a-zA-Z]
INTEGERDIGIT 		[0-9]+
FLOATNUMBER 	        [0-9]*([.][0-9]+)?(E[+-]?[0-9]+)?
CHARACTER 	        '.'
CHARACTEREXCEPTION 	'\\[ntabfv0\\r"]'

IDENTIFIER 	        [A-Za-z_]([A-Za-z0-9_])*

DECIMALPOINTER 	        [0-9]*[.][0-9]*([.]+[0-9]*)*
ILLFORMEDNUMBER	        [0-9]*((E[+-]?[0-9]*)([.][0-9]+)+)
INVALIDIDENTIFIER 	[0-9]+([A-Za-z_]+)[A-Za-z0-9_]*
CHARACTERERROR	        '..+'
UNFINISHEDCHAR		('\\')|('[^']*)


%%


{NEWLINE}               {line_count++;}

"if"	                {
			         return IF;
		        }		

"else"	                {
			         return ELSE;
		        }

"for"	                {
			         return FOR;
		        }

"while"	                {
			         return WHILE;
		        }

"do"	                {
			         return DO;
		        }

"break"	                {
			         return BREAK;
		        }

"int"	                {
                                 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("INT");
				 yylval.symbolinfo = s;
			         return INT;
		        }

"char"	                {
			         return CHAR;
		        }

"float"	                {
                                 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("FLOAT");
				 yylval.symbolinfo = s;
			         return FLOAT;
		        }

"double"	        {
			         return DOUBLE;
		        }

"void"	                {
			         symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("VOID");
				 yylval.symbolinfo = s;
			         return VOID;
		        }

"return"	        {
			         return RETURN;
		        }

"switch"	        {
			         return SWITCH;
		        }

"case"	                {
			         return CASE;
		        }

"default"	        {
			         return DEFAULT;
		        }

"continue"	        {
			         return CONTINUE;
		        }

"println"               {
                                 return PRINTLN;
                        }


"+" |
"-"		        {
			         symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("ADDOP");
				 yylval.symbolinfo = s;
			         return ADDOP;
		        }
		
"*" |
"/" |
"%" 		        {
				 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("MULOP");
				 yylval.symbolinfo = s;
			         return MULOP;
		        }

"++"                    {
                                 return INCOP;
                        } 

"--" 		        {
				 return DECOP;
		        }

"<" |
">" |
"<=" |
">=" |
"==" |
"!=" 		        {
				 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("RELOP");
				 yylval.symbolinfo = s;
			         return RELOP;
		        }

"=" 		        {
				 return ASSIGNOP;
		        }

"&&" | 
"||" 		        {
				 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("LOGICOP");
				 yylval.symbolinfo = s;
			         return LOGICOP;
		        }

"&" |
"|" |
"^" |
"<<" |
">>" 		        {
				 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("BITOP");
				 yylval.symbolinfo = s;
			         return BITOP;
		        }

"!" 		        {
				 return NOT;
		        }

"(" 		        {
				 return LPAREN;
		        }

")" 		        {
				 return RPAREN;
		        }

"{" 		        {
				 return LCURL;
		        }

"}" 		        {
				 return RCURL;
		        }

"[" 		        {
				 return LTHIRD;
		        }

"]" 		        {
				 return RTHIRD;
		        }

"," 		        {
				 return COMMA;
		        }

";" 		        {
				 return SEMICOLON;
		        }


{INTEGERDIGIT} 	        {
				 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("CONST_INT");
				 yylval.symbolinfo = s;
			         return CONST_INT;	
                        }

{FLOATNUMBER}	        {
				 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("CONST_FLOAT");
				 yylval.symbolinfo = s;
			         return CONST_FLOAT;	
			}

{CHARACTER}	        {
				 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("CONST_CHAR");
				 yylval.symbolinfo = s;
			         return CONST_CHAR;	
			}

{CHARACTEREXCEPTION}    {
				 symbolInfo *s = new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("CONST_CHAR");
				 yylval.symbolinfo = s;
			         return CONST_CHAR;	
                        }



{IDENTIFIER}            {
	                         symbolInfo *s= new  symbolInfo();
                                 s->set_name(yytext);
                                 s->set_type("ID");
				 yylval.symbolinfo = s;
			         return ID;	
                        }

.			{}



%%


/*int main(int argc , char *argv[])
{
        
        st.enter_scope(sc);

        //FlexLexer* lexer = new yyFlexLexer();
        	
        FILE *input_file;

	if(argc!=2){
		printf("Please provide input file name\n");
		return 0;
	}
	
        input_file = fopen(argv[1] , "r");	

	if(input_file == NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	log_output = fopen("1605008_log.txt","w");
	token_output = fopen("1605008_token.txt","w");
         
        yyin = input_file;
	//lexer->yyinput = input_file;
	yylex();

	fclose(yyin);
        fclose(input_file);
 	fclose(token_output);
	fclose(log_output);
	return 0;
}

<INITIAL>[/][*]	        {
				yymore();
				BEGIN(COMMENT_MULTI);
                                track_line = yylineno;
			}

<COMMENT_MULTI>.        {
	                        yymore(); 
                        }

<COMMENT_MULTI>{NEWLINE} {
	                        yymore(); 
                        }

<COMMENT_MULTI>[*][/]   {
                                fprintf(log_output,"Line no %d: TOKEN <COMMENT> Lexeme %s found\n\n",track_line,yytext);
	                        BEGIN(INITIAL);
                        }

<COMMENT_MULTI><<EOF>>  {
	                        fprintf(log_output,"Line no %d: Unterminated comment found\n\n",track_line);
	                        error_number++;
                        }

<INITIAL>\/\/           {
                                yymore();
                                BEGIN(COMMENT_DS);
                                track_line = yylineno;
                        }

<COMMENT_DS>.           {
                                yymore();
                        }

<COMMENT_DS>\\.         {
                                yymore();
                        }

<COMMENT_DS>\\{NEWLINE} {
                                yymore();
                        }

<COMMENT_DS>{NEWLINE}   {
                                fprintf(log_output,"Line no %d: TOKEN <COMMENT> Lexeme %s found\n\n",track_line,yytext);
                                BEGIN(INITIAL);
                        }



<INITIAL>\"             {
                                BEGIN(STRING);
                                all = "\"";
                                token = "";
                                start = yylineno;
                        }

<STRING>\\{NEWLINE}     {
                                all += yytext;
                        }

<STRING>\\[ntafrbv0\"\'\\] {
                                all += yytext;
                                token += return_real_value(yytext[1]);
                        }


<STRING>{NEWLINE}     {
                                fprintf(log_output, "\nError at line no %d: Unterminated String %s\n", start, all.c_str());
                                error_number++;
                                BEGIN(INITIAL);
                        }

<STRING><<EOF>>         {
                                fprintf(log_output, "\nError at line no %d: Unterminated String %s\n", start, all.c_str());
                                error_number++;
                                return 0;
                        }

<STRING>\"              { 
                                all += '\"';
                                fprintf(token_output, "<STRING, %s> ", token.c_str());
                                fprintf(log_output, "Line No. %d: Token <STRING> Lexeme %s found\n", start, all.c_str());
                                BEGIN(INITIAL);
                        }

<STRING>.               {
                                all += yytext;
                                token += yytext[0];
                        }
{DECIMALPOINTER}        {
			        fprintf(log_output,"Error at line no %d: Decimal point error %s\n\n",yylineno,yytext);
			        error_number++;
			}

{ILLFORMEDNUMBER}       {
			        fprintf(log_output,"Error at line no %d: Ill formed number %s\n\n",yylineno,yytext);
			        error_number++;
			}

{INVALIDIDENTIFIER}     {
			        fprintf(log_output,"Error at line no %d: Invalid ID. Number on prefix  %s\n\n",yylineno,yytext);
			        error_number++;
		        }

{CHARACTERERROR} 	{
			        fprintf(log_output,"Error at line no %d: Wrong formed character %s\n\n",yylineno,yytext);
			        error_number++;
		        }

{UNFINISHEDCHAR}        {
			        fprintf(log_output,"Error at line no %d: Unfinished character %s\n\n",yylineno,yytext);
			        error_number++;
			}


<<EOF>> 	        {
			        fprintf(log_output,"Total Line Number: %d\n\n",yylineno); 
			        fprintf(log_output,"Total Errors: %d\n",error_number);
			        return 0;
			}



DECIMALPOINTER 	        [0-9]*[.][0-9]*([.]+[0-9]*)*
ILLFORMEDNUMBER	        [0-9]*((E[+-]?[0-9]*)([.][0-9]+)+)
INVALIDIDENTIFIER 	[0-9]+([A-Za-z_]+)[A-Za-z0-9_]*
CHARACTERERROR	        '..+'
UNFINISHEDCHAR		('\\')|('[^']*)
*/
