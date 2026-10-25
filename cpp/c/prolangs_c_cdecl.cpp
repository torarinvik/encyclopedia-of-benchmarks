/* Clean-room bounded declarator parser; no upstream source text is copied. */
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr int MAX_INPUT=96, MAX_NAME=16, MAX_OPS=12, MAX_DEPTH=6, MAX_PARAMS=3, MAX_OUTPUT=128;
enum { POINTER=1, ARRAY=2, FUNCTION=3, CHAR_TYPE=1, INT_TYPE=2, FLOAT_TYPE=3, DOUBLE_TYPE=4, VOID_TYPE=5 };
struct Op { int kind=0, value=0, argc=0, param_type[MAX_PARAMS]{}, param_ptrs[MAX_PARAMS]{}; };
struct Parser { const std::int64_t* input; std::size_t length, pos=0; };

void skip_space(Parser& p) {
    while (p.pos<p.length) { int c=static_cast<int>(p.input[p.pos]); if (c!=' '&&c!='\t'&&c!='\n'&&c!='\r') break; ++p.pos; }
}
int peek(Parser& p) { skip_space(p); return p.pos<p.length?static_cast<int>(p.input[p.pos]):-1; }
bool consume(Parser& p,int wanted) { if(peek(p)!=wanted)return false; ++p.pos; return true; }
bool word(Parser& p,char* out,std::size_t cap) {
    int c=peek(p); if(!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||c=='_'))return false;
    std::size_t used=0;
    while(p.pos<p.length&&(c=static_cast<int>(p.input[p.pos]))>=0&&((c>='A'&&c<='Z')||(c>='a'&&c<='z')||(c>='0'&&c<='9')||c=='_')) {
        if(used+1>=cap)return false; out[used++]=static_cast<char>(c); ++p.pos;
    }
    out[used]='\0'; return true;
}
int base_type(Parser& p) {
    char t[MAX_NAME+1]; if(!word(p,t,sizeof t))return 0;
    if(std::strcmp(t,"char")==0)return CHAR_TYPE; if(std::strcmp(t,"int")==0)return INT_TYPE;
    if(std::strcmp(t,"float")==0)return FLOAT_TYPE; if(std::strcmp(t,"double")==0)return DOUBLE_TYPE;
    if(std::strcmp(t,"void")==0)return VOID_TYPE; return 0;
}
bool decimal(Parser& p,int& value) {
    int c=peek(p); if(c<'0'||c>'9')return false; int result=0;
    while(p.pos<p.length&&(c=static_cast<int>(p.input[p.pos]))>='0'&&c<='9'){ result=result*10+c-'0'; if(result>99)return false; ++p.pos; }
    if(result<1)return false; value=result; return true;
}
bool append(Op* ops,int& count,const Op& item){ if(count>=MAX_OPS)return false; ops[count++]=item; return true; }
bool params(Parser& p,Op& item) {
    if(!consume(p,'('))return false; item.argc=0; if(consume(p,')'))return true;
    for(;;){
        if(item.argc>=MAX_PARAMS)return false;
        int t=base_type(p),stars=0; if(!t)return false;
        while(consume(p,'*'))if(++stars>8)return false;
        item.param_type[item.argc]=t; item.param_ptrs[item.argc]=stars; ++item.argc;
        if(consume(p,')'))break; if(!consume(p,','))return false;
    }
    if(item.argc==1&&item.param_type[0]==VOID_TYPE&&item.param_ptrs[0]==0)item.argc=0;
    else for(int a=0;a<item.argc;++a)if(item.param_type[a]==VOID_TYPE&&item.param_ptrs[a]==0)return false;
    return true;
}
bool declarator(Parser& p,char* name,Op* ops,int& count,int depth) {
    if(depth>MAX_DEPTH)return false; int stars=0;
    while(consume(p,'*'))if(++stars>8)return false;
    if(consume(p,'(')){ if(!declarator(p,name,ops,count,depth+1)||!consume(p,')'))return false; }
    else if(name[0]!='\0'||!word(p,name,MAX_NAME+1))return false;
    for(;;){ int c=peek(p);
        if(c=='['){ Op item{}; item.kind=ARRAY; if(!consume(p,'[')||!decimal(p,item.value)||!consume(p,']')||!append(ops,count,item))return false; }
        else if(c=='('){ Op item{}; item.kind=FUNCTION; if(!params(p,item)||!append(ops,count,item))return false; }
        else break;
    }
    while(stars-->0){ Op item{}; item.kind=POINTER; if(!append(ops,count,item))return false; }
    return true;
}
bool valid_order(int base,const Op* ops,int count){
    int current=0; bool is_void=base==VOID_TYPE;
    for(int i=count-1;i>=0;--i){
        if(ops[i].kind==ARRAY){if(current==3||(current==0&&is_void))return false;current=2;is_void=false;}
        else if(ops[i].kind==FUNCTION){if(current==2||current==3)return false;current=3;is_void=false;}
        else if(ops[i].kind==POINTER){current=1;is_void=false;} else return false;
    }
    return true;
}
}

extern "C" std::int64_t prolangs_c_cdecl(const std::int64_t* input,std::size_t input_length,
                                           std::uint8_t* output,std::size_t output_capacity){
    if(!input||input_length<1||input_length>MAX_INPUT)return -1;
    for(std::size_t i=0;i<input_length;++i)if(input[i]<=0||input[i]>127)return -1;
    Parser p{input,input_length}; int base=base_type(p); char name[MAX_NAME+1]{}; Op ops[MAX_OPS]{}; int count=0;
    if(!base||!declarator(p,name,ops,count,0)||!valid_order(base,ops,count)||(base==VOID_TYPE&&count==0)||peek(p)!=-1)return -1;
    if(std::strcmp(name,"char")==0||std::strcmp(name,"int")==0||std::strcmp(name,"float")==0||std::strcmp(name,"double")==0||std::strcmp(name,"void")==0)return -1;
    std::uint8_t encoded[MAX_OUTPUT]{}; std::size_t used=0, n=std::strlen(name);
    encoded[used++]=static_cast<std::uint8_t>(base); encoded[used++]=static_cast<std::uint8_t>(n);
    for(std::size_t i=0;i<n;++i)encoded[used++]=static_cast<std::uint8_t>(name[i]);
    encoded[used++]=static_cast<std::uint8_t>(count);
    for(int i=0;i<count;++i){ encoded[used++]=static_cast<std::uint8_t>(ops[i].kind);
        if(ops[i].kind==ARRAY)encoded[used++]=static_cast<std::uint8_t>(ops[i].value);
        else if(ops[i].kind==FUNCTION){encoded[used++]=static_cast<std::uint8_t>(ops[i].argc);
            for(int a=0;a<ops[i].argc;++a){encoded[used++]=static_cast<std::uint8_t>(ops[i].param_type[a]);encoded[used++]=static_cast<std::uint8_t>(ops[i].param_ptrs[a]);}}
    }
    if(!output||output_capacity<used)return -2; std::memcpy(output,encoded,used); return static_cast<std::int64_t>(used);
}
