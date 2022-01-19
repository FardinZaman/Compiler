%option noyywrap
%option yylineno


%x TEMPLATE

%{
#include<stdio.h>
#include<stdlib.h>
#include<iostream>
#include<cstring>

using namespace std;

   int tracker = 0;
   string all;

%}





NEWLINE		        \r\n
WHITESPACE 	        [ \t\f\r\v]+

LETTER 		        [a-zA-Z]


IDENTIFIER 	        [A-Za-z_]([A-Za-z0-9_])*




%%


<INITIAL>{IDENTIFIER}\< {

                                yymore();
                                BEGIN(TEMPLATE);
                                all = "";
                                all += yytext;
                                tracker++;
}

<TEMPLATE>{IDENTIFIER}  {

                                yymore();
                                all += yytext;
}

<TEMPLATE>\<            {
                                yymore();
                                all += yytext;
                                tracker++;
}

<TEMPLATE>\>            {
                                yymore();
                                all += yytext;
                                tracker--;
}


<TEMPLATE><<EOF>>       {

                         if(tracker == 0)
                                     printf("Template %s detected",yytext);
                                else
                                     printf("Unfinished template");
                                BEGIN(INITIAL);
}



<<EOF>> 	        {
			        
			        return 0;
			}


%%


int main(int argc , char *argv[])
{
        
        

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
	
         
        yyin = input_file;
	//lexer->yyinput = input_file;
	yylex();

	fclose(yyin);
        fclose(input_file);

	return 0;
}
