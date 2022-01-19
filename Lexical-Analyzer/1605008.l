%option noyywrap
%option yylineno
%x COMMENT_MULTI
%x COMMENT_DS
%x STRING

%{

//#include<FlexLexer.h>
#include<stdio.h>
#include<stdlib.h>
#include<iostream>
#include<cstring>

#define INF 999999;

using namespace std;

bool receiver = false;

int line_count = 1;
int error_number = 0;
int track_line = 0;
string comment = "";
int start = 0;
string all;
string token;

FILE *log_output;
FILE *token_output;

int row;
int column;

int hash_1(string key , int number)
{
    unsigned long h = 5381;

    for(int i=0 ; i<key.size() ; i++)
    {
        h = (h<<5) + h + key[i];
    }

    return h%number;
}

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

struct search_output
{
    string name;
    string type;
    int hit;
};

class symbol_info
{
public:

    string name;
    string type;

public:

    symbol_info* link;

    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }

    string get_name()
    {
        return this->name;
    }

    string get_type()
    {
        return this->type;
    }
};

/*struct look_uo_output
{
    symbol_info* now;
    int row;
    int column;
};*/

class Linked_list
{
public:

    symbol_info* list;
    int length;

    Linked_list()
    {
        list = NULL;
        length = 0;
    }

    void insert_node(symbol_info h)
    {
        symbol_info* node = new symbol_info();
        node->set_name(h.get_name());
        node->set_type(h.get_type());

        node->link = NULL;

        if(list == NULL)
        {
            list = node;
            column = length;
            length++;
            return;
        }

        symbol_info* temp = list;

        while(temp->link != NULL)
        {
            temp = temp->link;
        }

        temp->link = node;
        column = length;
        length++;
    }

    search_output searching(string key)
    {
        symbol_info* temp = list;
        int hits = 0;

        search_output out;
        //cout<<8;
        //out.name = NULL;
        //out.type = NULL;

        while(temp != NULL)
        {
            if(temp->get_name().compare(key) == 0)
            {
                out.name = temp->get_name();
                out.type = temp->get_type();
                break;
            }
            temp = temp->link;
            hits++;
        }

        out.hit = hits;

        return out;
    }

    void delete_node(string key)
    {
        symbol_info* temp = list;
        symbol_info* prev = NULL;

        while(temp != NULL)
        {
            if(temp->get_name().compare(key) == 0)
                break;

            prev = temp;
            temp = temp->link;
        }

        if(temp == NULL)
            return;

        if(temp == list)
        {
            list = list->link;
            delete temp;
            length--;
        }

        else
        {
            prev->link = temp->link;
            delete temp;
            length--;
        }
    }

    int get_length()
    {
        return length;
    }
};

class scope_table
{
    Linked_list* table;
    int size;

public:

    int id;
    scope_table* parent_scope;

    scope_table(int n)
    {
        size = n;
        table = new Linked_list[size];
        parent_scope = NULL;
    }

    bool insert_item(string name , string type)
    {
        if(look_up(name) != NULL)
            return false;

        symbol_info s;
        s.set_name(name);
        s.set_type(type);

        int index = hash_1(name , size);
        row = index;
        table[index].insert_node(s);

        return true;
    }

    symbol_info* look_up(string name)
    {
        symbol_info* now = new symbol_info();
        int index = hash_1(name , size);

        search_output out = table[index].searching(name);

        if(out.hit == table[index].get_length())
            return NULL;

        now->set_name(out.name);
        now->set_type(out.type);

        row = index;
        column = out.hit;

        return now;
    }

    bool delete_node(string name)
    {
        if(look_up(name) == NULL)
            return false;

        int index = hash_1(name , size);

        table[index].delete_node(name);

        return true;
    }

    void print()
    {
        //freopen(log_output,"w",stdout);
        //cout<<"Scope Table # "<<this->id<<endl;
        fprintf(log_output,"Scope Table # %d\n",this->id);
        for(int i=0 ; i<size ; i++)
        {
            symbol_info* temp = table[i].list;
            if(temp == NULL)
                continue;
            //cout<<i<<" --> ";
            fprintf(log_output,"%d --> ",i);
            //symbol_info* temp = table[i].list;
            while(temp != NULL)
            {
                //cout<<"< "<<temp->get_name()<<" : "<<temp->get_type()<<" >  ";
                fprintf(log_output,"< %s : %s >",temp->name.c_str(),temp->type.c_str());
                temp = temp->link;
            }
            //cout<<endl;
            fprintf(log_output,"\n");
        }
        //cout<<endl;
        fprintf(log_output,"\n");
    }
};


class symbol_table
{
public:

    int id_track;
    scope_table* current_scope;
    scope_table* tracker;

    symbol_table()
    {
        current_scope = NULL;
        id_track = 1;
    }

    void enter_scope(scope_table* new_scope)
    {
        if(current_scope == NULL)
        {
            current_scope = new_scope;
            current_scope->id = id_track;
            id_track++;
            return;
        }

        new_scope->parent_scope = current_scope;
        current_scope = new_scope;
        current_scope->id = id_track;

        id_track++;
    }

    void exit_scope()
    {
        if(current_scope->parent_scope == NULL)
            current_scope = NULL;
        else
        {
            current_scope = current_scope->parent_scope;
        }

        id_track--;
    }

    bool insert_symbol(string name , string type)
    {
        return current_scope->insert_item(name , type);
    }

    bool remove_symbol(string name)
    {
        return current_scope->delete_node(name);
    }

    symbol_info* look_up(string name)
    {
        symbol_info* now;
        tracker = current_scope;

        while(tracker != NULL)
        {
            now = tracker->look_up(name);
            if(now != NULL)
                return now;

            tracker = tracker->parent_scope;
        }
        return NULL;
    }

    void print_current()
    {
        current_scope->print();
    }

    void print_all()
    {
        tracker = current_scope;
        while(tracker != NULL)
        {
            tracker->print();
            tracker = tracker->parent_scope;
        }
    }
};

symbol_table st;
scope_table* sc = new scope_table(7);
//st.enter_scope(sc);

%}

NEWLINE		        \r\n
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
			         fprintf(token_output,"<IF>");
			         fprintf(log_output,"Line no %d: TOKEN <IF> Lexeme %s found\n",yylineno,yytext);
		        }		

"else"	                {
			         fprintf(token_output,"<ELSE>");
			         fprintf(log_output,"Line no %d: TOKEN <ELSE> Lexeme %s found\n",yylineno,yytext);
		        }

"for"	                {
			         fprintf(token_output,"<FOR>");
			         fprintf(log_output,"Line no %d: TOKEN <FOR> Lexeme %s found\n",yylineno,yytext);
		        }

"while"	                {
			         fprintf(token_output,"<WHILE>");
			         fprintf(log_output,"Line no %d: TOKEN <WHILE> Lexeme %s found\n",yylineno,yytext);
		        }

"do"	                {
			         fprintf(token_output,"<DO>");
			         fprintf(log_output,"Line no %d: TOKEN <DO> Lexeme %s found\n",yylineno,yytext);
		        }

"break"	                {
			         fprintf(token_output,"<BREAK>");
			         fprintf(log_output,"Line no %d: TOKEN <BREAK> Lexeme %s found\n",yylineno,yytext);
		        }

"int"	                {
			         fprintf(token_output,"<INT>");
			         fprintf(log_output,"Line no %d: TOKEN <INT> Lexeme %s found\n",yylineno,yytext);
		        }

"char"	                {
			         fprintf(token_output,"<CHAR>");
			         fprintf(log_output,"Line no %d: TOKEN <CHAR> Lexeme %s found\n",yylineno,yytext);
		        }

"float"	                {
			         fprintf(token_output,"<FLOAT>");
			         fprintf(log_output,"Line no %d: TOKEN <FLOAT> Lexeme %s found\n",yylineno,yytext);
		        }

"double"	        {
			         fprintf(token_output,"<DOUBLE>");
			         fprintf(log_output,"Line no %d: TOKEN <DOUBLE> Lexeme %s found\n",yylineno,yytext);
		        }

"void"	                {
			         fprintf(token_output,"<VOID>");
			         fprintf(log_output,"Line no %d: TOKEN <VOID> Lexeme %s found\n",yylineno,yytext);
		        }

"return"	        {
			         fprintf(token_output,"<RETURN>");
			         fprintf(log_output,"Line no %d: TOKEN <RETURN> Lexeme %s found\n",yylineno,yytext);
		        }

"switch"	        {
			         fprintf(token_output,"<SWITCH>");
			         fprintf(log_output,"Line no %d: TOKEN <SWITCH> Lexeme %s found\n",yylineno,yytext);
		        }

"case"	                {
			         fprintf(token_output,"<CASE>");
			         fprintf(log_output,"Line no %d: TOKEN <CASE> Lexeme %s found\n",yylineno,yytext);
		        }

"default"	        {
			         fprintf(token_output,"<DEFAULT>");
			         fprintf(log_output,"Line no %d: TOKEN <DEFAULT> Lexeme %s found\n",yylineno,yytext);
		        }

"continue"	        {
			         fprintf(token_output,"<CONTINUE>");
			         fprintf(log_output,"Line no %d: TOKEN <CONTINUE> Lexeme %s found\n",yylineno,yytext);
		        }


"+" |
"-"		        {
			         fprintf(token_output,"<ADDOP,%s>",yytext);
			         fprintf(log_output,"Line no %d: TOKEN <ADDOP> Lexeme %s found\n",yylineno,yytext);
                                 receiver = st.insert_symbol(yytext,"ADDOP");
                                 if(receiver == false)
                                 {
                                       fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                 }
                                 st.print_current();
		        }
		
"*" |
"/" |
"%" 		        {
				fprintf(token_output,"<MULOP,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <MULOP> Lexeme %s found\n",yylineno,yytext);
                                receiver = st.insert_symbol(yytext,"MULOP");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();
		        }

"++" |
"--" 		        {
				fprintf(token_output,"<INCOP,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <INCOP> Lexeme %s found\n",yylineno,yytext);
                                receiver = st.insert_symbol(yytext,"INCOP");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();
		        }

"<" |
">" |
"<=" |
">=" |
"==" |
"!=" 		        {
				fprintf(token_output,"<RELOP,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <RELOP> Lexeme %s found\n",yylineno,yytext);
                                receiver = st.insert_symbol(yytext,"RELOP");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();
		        }

"=" 		        {
				fprintf(token_output,"<ASSIGNOP,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <ASSIGNOP> Lexeme %s found\n",yylineno,yytext);
                                receiver = st.insert_symbol(yytext,"ASSIGNOP");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();
		        }

"&&" | 
"||" 		        {
				fprintf(token_output,"<LOGICOP,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <LOGICOP> Lexeme %s found\n",yylineno,yytext);
                                receiver = st.insert_symbol(yytext,"LOGICOP");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();
		        }

"&" |
"|" |
"^" |
"<<" |
">>" 		        {
				fprintf(token_output,"<BITOP,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <BITOP> Lexeme %s found\n",yylineno,yytext);
                                receiver = st.insert_symbol(yytext,"BITOP");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();
		        }

"!" 		        {
				fprintf(token_output,"<NOT,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <NOT> Lexeme %s found\n",yylineno,yytext);
                                receiver = st.insert_symbol(yytext,"NOT");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();
		        }

"(" 		        {
				fprintf(token_output,"<LPAREN,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <LPAREN> Lexeme %s found\n",yylineno,yytext);
		        }

")" 		        {
				fprintf(token_output,"<RPAREN,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <RPAREN> Lexeme %s found\n",yylineno,yytext);
		        }

"{" 		        {
				fprintf(token_output,"<LCURL,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <LCURL> Lexeme %s found\n",yylineno,yytext);
		        }

"}" 		        {
				fprintf(token_output,"<RCURL,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <RCURL> Lexeme %s found\n",yylineno,yytext);
		        }

"[" 		        {
				fprintf(token_output,"<LTHIRD,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <LTHIRD> Lexeme %s found\n",yylineno,yytext);
		        }

"]" 		        {
				fprintf(token_output,"<RTHIRD,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <RTHIRD> Lexeme %s found\n",yylineno,yytext);
		        }

"," 		        {
				fprintf(token_output,"<COMMA,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <COMMA> Lexeme %s found\n",yylineno,yytext);
		        }

";" 		        {
				fprintf(token_output,"<SEMICOLON,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <SEMICOLON> Lexeme %s found\n",yylineno,yytext);
		        }


{INTEGERDIGIT} 	        {
				fprintf(token_output,"<CONST_INT,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <CONST_INT> Lexeme %s found\n",yylineno,yytext);
				receiver = st.insert_symbol(yytext,"CONST_INT");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();	
                        }

{FLOATNUMBER}	        {
				fprintf(token_output,"<CONST_FLOAT,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n\n",yylineno,yytext);
				receiver = st.insert_symbol(yytext,"CONST_FLOAT");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();	
			}

{CHARACTER}	        {
				fprintf(token_output,"<CONST_CHAR,%c>",yytext[1]);
				fprintf(log_output,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n\n",yylineno,yytext);
				receiver = st.insert_symbol(yytext,"CONST_CHAR");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();	
			}

{CHARACTEREXCEPTION}    {
				fprintf(token_output,"<CONST_CHAR,%s>",yytext);
				fprintf(log_output,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n\n",yylineno,yytext);
				receiver = st.insert_symbol(yytext,"CONST_CHAR");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();	
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


{IDENTIFIER}            {
	                        fprintf(token_output,"<ID,%s>",yytext);
	                        fprintf(log_output,"Line no %d: TOKEN <ID> Lexeme %s found\n",yylineno,yytext);
	                        receiver = st.insert_symbol(yytext,"ID");
                                if(receiver == false)
                                {
                                      fprintf(log_output,"Symbol already exist in the Symbol Table\n");
                                }
                                st.print_current();	
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


%%


int main(int argc , char *argv[])
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
