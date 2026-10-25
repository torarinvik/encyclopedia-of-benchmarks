module prolangs_c_cdecl;

/* Clean-room bounded declarator parser; no upstream source text is copied. */
const usz MAX_INPUT=96, MAX_NAME=16, MAX_OPS=12, MAX_DEPTH=6, MAX_PARAMS=3, MAX_OUTPUT=128;
const int OP_POINTER=1, OP_ARRAY=2, OP_FUNCTION=3;
const int TYPE_CHAR=1, TYPE_INT=2, TYPE_FLOAT=3, TYPE_DOUBLE=4, TYPE_VOID=5;
struct Op { int kind; int value; int argc; int[3] param_type; int[3] param_ptrs; }
struct Parser { long* input; usz length; usz pos; }

fn void skip_space(Parser* p) {
    while (p.pos < p.length) { long c=p.input[p.pos]; if(c!=' '&&c!='\t'&&c!='\n'&&c!='\r') break; p.pos++; }
}
fn long peek(Parser* p) { skip_space(p); if(p.pos<p.length)return p.input[p.pos]; return -1; }
fn bool consume(Parser* p,long wanted) { if(peek(p)!=wanted)return false; p.pos++; return true; }
fn bool word(Parser* p,char* out,usz capacity) {
    long c=peek(p); if(!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||c=='_'))return false;
    usz used=0;
    while(p.pos<p.length&&(c=p.input[p.pos])>=0&&((c>='A'&&c<='Z')||(c>='a'&&c<='z')||(c>='0'&&c<='9')||c=='_')) {
        if(used+1>=capacity)return false; out[used]=(char)c; used++; p.pos++;
    }
    out[used]='\0'; return true;
}
fn int base_type(Parser* p) {
    char[17] token = zeroed; if(!word(p,&token[0],17))return 0;
    if(token[0]=='c'&&token[1]=='h'&&token[2]=='a'&&token[3]=='r'&&token[4]=='\0')return TYPE_CHAR;
    if(token[0]=='i'&&token[1]=='n'&&token[2]=='t'&&token[3]=='\0')return TYPE_INT;
    if(token[0]=='f'&&token[1]=='l'&&token[2]=='o'&&token[3]=='a'&&token[4]=='t'&&token[5]=='\0')return TYPE_FLOAT;
    if(token[0]=='d'&&token[1]=='o'&&token[2]=='u'&&token[3]=='b'&&token[4]=='l'&&token[5]=='e'&&token[6]=='\0')return TYPE_DOUBLE;
    if(token[0]=='v'&&token[1]=='o'&&token[2]=='i'&&token[3]=='d'&&token[4]=='\0')return TYPE_VOID;
    return 0;
}
fn bool decimal(Parser* p,int* value) {
    long c=peek(p); if(c<'0'||c>'9')return false; int result=0;
    while(p.pos<p.length&&(c=p.input[p.pos])>='0'&&c<='9'){result=result*10+(int)(c-'0');if(result>99)return false;p.pos++;}
    if(result<1)return false;*value=result;return true;
}
fn bool append_op(Op* ops,int* count,Op item){if(*count>=MAX_OPS)return false;ops[*count]=item;*count=*count+1;return true;}
fn bool parse_params(Parser* p,Op* item) {
    item.argc=0;if(!consume(p,'('))return false;if(consume(p,')'))return true;
    while(true){if(item.argc>=MAX_PARAMS)return false;int t=base_type(p),stars=0;if(t==0)return false;
        while(consume(p,'*')){stars++;if(stars>8)return false;}
        item.param_type[item.argc]=t;item.param_ptrs[item.argc]=stars;item.argc++;
        if(consume(p,')'))break;if(!consume(p,','))return false;
    }
    if(item.argc==1&&item.param_type[0]==TYPE_VOID&&item.param_ptrs[0]==0)item.argc=0;
    else for(int a=0;a<item.argc;a++)if(item.param_type[a]==TYPE_VOID&&item.param_ptrs[a]==0)return false;
    return true;
}
fn bool parse_declarator(Parser* p,char* name,Op* ops,int* count,int depth) {
    if(depth>MAX_DEPTH)return false;int stars=0;while(consume(p,'*')){stars++;if(stars>8)return false;}
    if(consume(p,'(')){if(!parse_declarator(p,name,ops,count,depth+1)||!consume(p,')'))return false;}
    else if(name[0]!='\0'||!word(p,name,MAX_NAME+1))return false;
    while(true){long c=peek(p);
        if(c=='['){Op item={0};item.kind=OP_ARRAY;if(!consume(p,'[')||!decimal(p,&item.value)||!consume(p,']')||!append_op(ops,count,item))return false;}
        else if(c=='('){Op item={0};item.kind=OP_FUNCTION;if(!parse_params(p,&item)||!append_op(ops,count,item))return false;}
        else break;
    }
    while(stars>0){Op item={0};item.kind=OP_POINTER;if(!append_op(ops,count,item))return false;stars--;}
    return true;
}
fn bool valid_order(int base,Op* ops,int count){int current=0;bool is_void=base==TYPE_VOID;
    for(int i=count-1;i>=0;i--){if(ops[i].kind==OP_ARRAY){if(current==3||(current==0&&is_void))return false;current=2;is_void=false;}
        else if(ops[i].kind==OP_FUNCTION){if(current==2||current==3)return false;current=3;is_void=false;}
        else if(ops[i].kind==OP_POINTER){current=1;is_void=false;}else return false;}return true;}

fn long prolangs_c_cdecl(long* input,usz input_length,uchar* output,usz output_capacity)
    @export("prolangs_c_cdecl") {
    if(input==null||input_length<1||input_length>MAX_INPUT)return -1;
    for(usz i=0;i<input_length;i++)if(input[i]<=0||input[i]>127)return -1;
    Parser p={input,input_length,0};int base=base_type(&p);char[MAX_NAME+1] name=zeroed;Op[MAX_OPS] ops=zeroed;int count=0;
    if(base==0||!parse_declarator(&p,&name[0],&ops[0],&count,0)||!valid_order(base,&ops[0],count)||(base==TYPE_VOID&&count==0)||peek(&p)!=-1)return -1;
    usz name_length=0;while(name_length<MAX_NAME&&name[name_length]!='\0')name_length++;
    if((name_length==3&&name[0]=='i'&&name[1]=='n'&&name[2]=='t')||(name_length==4&&name[0]=='c'&&name[1]=='h'&&name[2]=='a'&&name[3]=='r')||(name_length==5&&name[0]=='f'&&name[1]=='l'&&name[2]=='o'&&name[3]=='a'&&name[4]=='t')||(name_length==6&&name[0]=='d'&&name[1]=='o'&&name[2]=='u'&&name[3]=='b'&&name[4]=='l'&&name[5]=='e')||(name_length==4&&name[0]=='v'&&name[1]=='o'&&name[2]=='i'&&name[3]=='d'))return -1;
    uchar[MAX_OUTPUT] encoded=zeroed;usz used=0;encoded[used++]=(uchar)base;encoded[used++]=(uchar)name_length;
    for(usz i=0;i<name_length;i++)encoded[used++]=(uchar)name[i];encoded[used++]=(uchar)count;
    for(int i=0;i<count;i++){encoded[used++]=(uchar)ops[i].kind;
        if(ops[i].kind==OP_ARRAY)encoded[used++]=(uchar)ops[i].value;
        else if(ops[i].kind==OP_FUNCTION){encoded[used++]=(uchar)ops[i].argc;for(int a=0;a<ops[i].argc;a++){encoded[used++]=(uchar)ops[i].param_type[a];encoded[used++]=(uchar)ops[i].param_ptrs[a];}}
    }
    if(output==null||output_capacity<used)return -2;for(usz i=0;i<used;i++)output[i]=encoded[i];return (long)used;
}
