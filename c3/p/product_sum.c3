module product_sum;
const long LIST_BEGIN=2001, LIST_END=2002, MAX_TOKENS=128;
struct Parser { long* tokens; usz count; usz cursor; bool valid; }
fn long parse_list(Parser* p,long depth,bool nested){
    if(depth>16){p.valid=false;return 0;}
    long total=0;
    while(p.cursor<p.count){long x=p.tokens[p.cursor++];
        if(x==LIST_END){if(!nested)p.valid=false;return total*depth;}
        if(x==LIST_BEGIN)total+=parse_list(p,depth+1,true);
        else if(x>=-1000&&x<=1000)total+=x;
        else{p.valid=false;return 0;}
        if(!p.valid)return 0;
    }
    if(nested)p.valid=false;
    return total*depth;
}
fn long product_sum(long* v,usz n) @export("product_sum"){
    if(v==null||n<1||n>129||v[0]<0||v[0]>MAX_TOKENS||n!=(usz)v[0]+1)return -1;
    Parser p={v+1,(usz)v[0],0,true};long answer=parse_list(&p,1,false);
    return p.valid&&p.cursor==p.count?answer:-1;
}
