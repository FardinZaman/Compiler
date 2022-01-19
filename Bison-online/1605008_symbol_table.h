#include<stdio.h>
#include<cstdlib>
#include<iostream>
#include<cstring>
#include<bits/stdc++.h>

#define INF 999999;

using namespace std;

class Function
{
    string return_type;
    int number_of_parameters;

    vector<string>parameter_list;
    vector<string>parameter_type_list;

    int defined;

public:

    Function()
    {
        return_type = "";
        number_of_parameters = 0;
        parameter_list.clear();
        parameter_type_list.clear();
        defined = 0;
    }

    void set_return_type(string type)
    {
        this->return_type = type;
    }

    string get_return_type()
    {
        return return_type;
    }

    void set_number_of_parameters()
    {
        number_of_parameters = parameter_list.size();
    }

    int get_number_of_parameters()
    {
        return number_of_parameters;
    }

    void add_parameter(string parameter_name , string parameter_type)
    {
        parameter_list.push_back(parameter_name);
        parameter_type_list.push_back(parameter_type);
        set_number_of_parameters();
    }

    vector<string> get_parameter_list()
    {
        return parameter_list;
    }

    vector<string> get_parameter_type_list()
    {
        return parameter_type_list;
    }

    void set_defined()
    {
        this->defined = 1;
    }

    bool get_defined()
    {
        return defined;
    }
       

};

//int //row;
//int //column;
extern FILE* logfile;

inline int hash_1(string key , int number)
{
    unsigned long h = 5381;

    for(int i=0 ; i<key.size() ; i++)
    {
        h = (h<<5) + h + key[i];
    }

    return h%number;
}

struct search_output
{
    string name;
    string type;
    string realtype;
    int hit;
};

class symbolInfo
{
public:

    string name;
    string type;
    string realtype;

public:

    symbolInfo* link;
    Function* function;

    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }

    void set_realtype(string realtype)
    {
        this->realtype = realtype;
    }

    string get_name()
    {
        return this->name;
    }

    string get_type()
    {
        return this->type;
    }

    string get_realtype()
    {
        return this->realtype;
    }

    void set_function()
    {
        this->function = new Function();
    }

    Function* get_function()
    {
        return this->function;
    }
};

/*struct look_uo_output
{
    symbolInfo* now;
    int //row;
    int //column;
};*/

class Linked_list
{
public:

    symbolInfo* list;
    int length;

    Linked_list()
    {
        list = NULL;
        length = 0;
    }

    void insert_node(symbolInfo h)
    {
        symbolInfo* node = new symbolInfo();
        node->set_name(h.get_name());
        node->set_type(h.get_type());
        node->set_realtype(h.get_realtype());	

        node->link = NULL;

        if(list == NULL)
        {
            list = node;
            //column = length;
            length++;
            return;
        }

        symbolInfo* temp = list;

        while(temp->link != NULL)
        {
            temp = temp->link;
        }

        temp->link = node;
        //column = length;
        length++;
    }

    symbolInfo* searching(string key)
    {
        symbolInfo* temp = list;
       
        while(temp != NULL)
        {
            if(temp->get_name().compare(key) == 0)
            {
                 return temp;
            }
            temp = temp->link;
        }
        return temp;
    }

    /*search_output searching(string key)
    {
        symbolInfo* temp = list;
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
                out.realtype = temp->get_realtype();
                break;
            }
            temp = temp->link;
            hits++;
        }

        out.hit = hits;

        return out;
    }*/

    void delete_node(string key)
    {
        symbolInfo* temp = list;
        symbolInfo* prev = NULL;

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

        symbolInfo s;
        s.set_name(name);
        s.set_type(type);

        int index = hash_1(name , size);
        //row = index;
        table[index].insert_node(s);

        return true;
    }

    bool insert_item(string name , string type , string realtype)
    {
        if(look_up(name) != NULL)
            return false;

        symbolInfo s;
        s.set_name(name);
        s.set_type(type);
        s.set_realtype(realtype);

        int index = hash_1(name , size);
        //row = index;
        table[index].insert_node(s);

        return true;
    }

    symbolInfo* look_up(string name)
    {
        symbolInfo* now = new symbolInfo();
        int index = hash_1(name , size);
        
        now = table[index].searching(name);
        /*search_output out = table[index].searching(name);

        if(out.hit == table[index].get_length())
            return NULL;

        now->set_name(out.name);
        now->set_type(out.type);
        now->set_realtype(out.realtype);*/

        //row = index;
        //column = out.hit;

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
        fprintf(logfile,"Scope Table # %d\n",this->id);
        for(int i=0 ; i<size ; i++)
        {
            symbolInfo* temp = table[i].list;
            if(temp == NULL)
                continue;
            //cout<<i<<" --> ";
            fprintf(logfile,"%d --> ",i);
            //symbol_info* temp = table[i].list;
            while(temp != NULL)
            {
                //cout<<"< "<<temp->get_name()<<" : "<<temp->get_type()<<" >  ";
                fprintf(logfile,"< %s : %s >",temp->name.c_str(),temp->type.c_str());
                temp = temp->link;
            }
            //cout<<endl;
            fprintf(logfile,"\n");
        }
        //cout<<endl;
        fprintf(logfile,"\n");
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
            
            fprintf(logfile,"New ScopeTable with ID %d created\n\n",id_track);
            id_track++;
            return;
        }

        new_scope->parent_scope = current_scope;
        current_scope = new_scope;
        current_scope->id = id_track;
        fprintf(logfile,"New ScopeTable with ID %d created\n\n",id_track);

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
        fprintf(logfile,"ScopeTable with ID %d removed\n\n",id_track-1);
        //id_track--;
    }

    bool insert_symbol(string name , string type )
    {
        return current_scope->insert_item(name , type);
    }

    bool insert_symbol(string name , string type , string realtype)
    {
        return current_scope->insert_item(name , type , realtype);
    }

    bool remove_symbol(string name)
    {
        return current_scope->delete_node(name);
    }

    symbolInfo* look_up_current(string name)
    {
        return current_scope->look_up(name);
    }

    symbolInfo* look_up(string name)
    {
        symbolInfo* now;
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


/*int main()
{
    symbol_table st;
    int buckets;

    freopen("input.txt","r",stdin);

    cin>>buckets;
    scope_table* sc = new scope_table(buckets);
    st.enter_scope(sc);

    while(1){

    char start;
    cin>>start;

    if(start == 'S')
    {
        scope_table* sc = new scope_table(buckets);
        st.enter_scope(sc);
        cout<<"New ScopeTable with id "<<st.id_track - 1<<" created"<<endl;
    }

    else if(start == 'E')
    {
        st.exit_scope();
        cout<<"ScopeTable with id "<<st.id_track<<" removed"<<endl;
    }

    else if(start == 'I')
    {
        string name;
        string type;
        cin>>name;
        cin>>type;
        if(st.insert_symbol(name , type) == true)
            cout<<"Inserted in ScopeTable# "<<st.id_track - 1<<" at position "<<//row<<" , "<<//column<<endl;
        else
            cout<<"< "<<name<<" : "<<type<<" > already exists in current ScopeTable"<<endl;
    }

    else if(start == 'D')
    {
        string name;
        cin>>name;
        if(st.remove_symbol(name) == true)
        {
            cout<<"Found in ScopeTable# "<<st.current_scope->id<<" at position "<<//row<<" , "<<//column<<endl;
            cout<<"Deleted entry at "<<//row<<" , "<<//column<<" from current ScopeTable"<<endl;
        }
        else
            cout<<name<<" not found"<<endl;
    }

    else if(start == 'L')
    {
        string name;
        cin>>name;
        if(st.look_up(name) != NULL)
            cout<<"Found in ScopeTable# "<<st.tracker->id<<" at position "<<//row<<" , "<<//column<<endl;
        else
            cout<<"Not found"<<endl;
    }

    else if(start == 'P')
    {
        char target;
        cin>>target;
        if(target == 'A')
            st.print_all();
        if(target == 'C')
            st.print_current();
    }

    else
        break;

    }

}*/

