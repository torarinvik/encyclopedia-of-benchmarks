module measured_finger_tree_sequence;

const int MAX_Q = 32;
const int MAX_ROOTS = 65;
const int MAX_ARENA = 16384;
const int HALF_ARENA = 8192;
const int MAX_LEVELS = 16;
const int MAX_INPUT = 194;
const int MAX_PARSEABLE = 195;
const int MAX_OUTPUT = 1792;
const long MAX_VALUE = 1000000;
const long MAX_SUM = 64000000;
const int NODE_BASE = 8192;

struct Tree {
    int kind, level, plen, slen, mid;
    int[4] pre, suf;
    int count;
    long sum;
}
struct Node { int level, arity; int[3] child; int count; long sum; }
struct Ctx {
    Tree[HALF_ARENA] trees;
    Node[HALF_ARENA] nodes;
    int nt, nn, used, failed;
    int[MAX_LEVELS] empty_id;
    bool[MAX_LEVELS] empty_ready;
}
struct Root { int tree, length; long sum; }
struct Measure { int count; long sum; }
struct View { bool found; int item, tree; }
struct Split { bool found; int item, left, right; }

fn Measure ref_measure(Ctx* c, int ref) {
    if (ref < 0) return Measure{1, (long)(-ref - 1)};
    Node* n = &c.nodes[ref - NODE_BASE];
    return Measure{n.count, n.sum};
}
fn Measure tree_measure(Ctx* c, int id) { return Measure{c.trees[id].count, c.trees[id].sum}; }
fn Measure madd(Measure a, Measure b) { return Measure{a.count+b.count, a.sum+b.sum}; }
fn int alloc_tree(Ctx* c) {
    if (c.used >= MAX_ARENA || c.nt >= HALF_ARENA) { c.failed=1; return 0; }
    c.used+=1; int id=c.nt; c.nt+=1; return id;
}
fn int alloc_node(Ctx* c) {
    if (c.used >= MAX_ARENA || c.nn >= HALF_ARENA) { c.failed=1; return NODE_BASE; }
    c.used+=1; int id=c.nn; c.nn+=1; return NODE_BASE+id;
}
fn int empty_tree(Ctx* c, int level) {
    if (level<0 || level>=MAX_LEVELS) { c.failed=1; return 0; }
    if (c.empty_ready[level]) return c.empty_id[level];
    int id=alloc_tree(c); Tree* t=&c.trees[id]; t.kind=0;t.level=level;t.mid=-1;t.count=0;t.sum=0;t.plen=0;t.slen=0;
    c.empty_id[level]=id;c.empty_ready[level]=true;return id;
}
fn int make_node(Ctx* c, int child_level, int* items, int n) {
    int ref=alloc_node(c), id=ref-NODE_BASE; Node* out=&c.nodes[id];out.level=child_level+1;out.arity=n;out.count=0;out.sum=0;
    for(int i=0;i<n;i+=1){out.child[i]=items[i];Measure m=ref_measure(c,items[i]);out.count+=m.count;out.sum+=m.sum;}
    return ref;
}
fn int make_single(Ctx* c, int level, int item) {
    int id=alloc_tree(c);Tree* t=&c.trees[id];t.kind=1;t.level=level;t.pre[0]=item;t.plen=1;t.slen=0;t.mid=-1;Measure m=ref_measure(c,item);t.count=m.count;t.sum=m.sum;return id;
}
fn int make_deep(Ctx* c,int level,int* pre,int pn,int mid,int* suf,int sn){
    if(pn<=0||sn<=0){c.failed=1;return empty_tree(c,level);}int id=alloc_tree(c);Tree* t=&c.trees[id];t.kind=2;t.level=level;t.plen=pn;t.slen=sn;t.mid=mid;Measure m=tree_measure(c,mid);for(int i=0;i<pn;i+=1){t.pre[i]=pre[i];m=madd(m,ref_measure(c,pre[i]));}for(int i=0;i<sn;i+=1){t.suf[i]=suf[i];m=madd(m,ref_measure(c,suf[i]));}t.count=m.count;t.sum=m.sum;return id;
}
fn int cons(Ctx* c,int level,int item,int id);
fn int snoc(Ctx* c,int level,int id,int item);
fn int from_items(Ctx* c,int level,int* items,int n){int out=empty_tree(c,level);for(int i=0;i<n;i+=1)out=snoc(c,level,out,items[i]);return out;}
fn int cons(Ctx* c,int level,int item,int id){Tree t=c.trees[id];if(t.kind==0)return make_single(c,level,item);if(t.kind==1){int[1] p={item};int[1] s={t.pre[0]};return make_deep(c,level,&p[0],1,empty_tree(c,level+1),&s[0],1);}if(t.plen<4){int[4] p;p[0]=item;for(int i=0;i<t.plen;i+=1)p[i+1]=t.pre[i];return make_deep(c,level,&p[0],t.plen+1,t.mid,&t.suf[0],t.slen);}int[3] g={t.pre[1],t.pre[2],t.pre[3]};int m=cons(c,level+1,make_node(c,level,&g[0],3),t.mid);int[2] p={item,t.pre[0]};return make_deep(c,level,&p[0],2,m,&t.suf[0],t.slen);}
fn int snoc(Ctx* c,int level,int id,int item){Tree t=c.trees[id];if(t.kind==0)return make_single(c,level,item);if(t.kind==1){int[1] p={t.pre[0]};int[1] s={item};return make_deep(c,level,&p[0],1,empty_tree(c,level+1),&s[0],1);}if(t.slen<4){int[4] s;for(int i=0;i<t.slen;i+=1)s[i]=t.suf[i];s[t.slen]=item;return make_deep(c,level,&t.pre[0],t.plen,t.mid,&s[0],t.slen+1);}int[3] g={t.suf[0],t.suf[1],t.suf[2]};int m=snoc(c,level+1,t.mid,make_node(c,level,&g[0],3));int[2] s={t.suf[3],item};return make_deep(c,level,&t.pre[0],t.plen,m,&s[0],2);}
fn View view_left(Ctx* c,int level,int id){Tree t=c.trees[id];if(t.kind==0)return View{false,0,id};if(t.kind==1)return View{true,t.pre[0],empty_tree(c,level)};int item=t.pre[0],rest;if(t.plen>1)rest=make_deep(c,level,&t.pre[1],t.plen-1,t.mid,&t.suf[0],t.slen);else{View mv=view_left(c,level+1,t.mid);if(!mv.found)rest=from_items(c,level,&t.suf[0],t.slen);else{Node n=c.nodes[mv.item-NODE_BASE];rest=make_deep(c,level,&n.child[0],n.arity,mv.tree,&t.suf[0],t.slen);}}return View{true,item,rest};}
fn View view_right(Ctx* c,int level,int id){Tree t=c.trees[id];if(t.kind==0)return View{false,0,id};if(t.kind==1)return View{true,t.pre[0],empty_tree(c,level)};int item=t.suf[t.slen-1],rest;if(t.slen>1)rest=make_deep(c,level,&t.pre[0],t.plen,t.mid,&t.suf[0],t.slen-1);else{View mv=view_right(c,level+1,t.mid);if(!mv.found)rest=from_items(c,level,&t.pre[0],t.plen);else{Node n=c.nodes[mv.item-NODE_BASE];rest=make_deep(c,level,&t.pre[0],t.plen,mv.tree,&n.child[0],n.arity);}}return View{true,item,rest};}
fn int deep_left(Ctx* c,int level,int* pre,int pn,int mid,int* suf,int sn){if(pn>0)return make_deep(c,level,pre,pn,mid,suf,sn);View v=view_left(c,level+1,mid);if(!v.found)return from_items(c,level,suf,sn);Node n=c.nodes[v.item-NODE_BASE];return make_deep(c,level,&n.child[0],n.arity,v.tree,suf,sn);}
fn int deep_right(Ctx* c,int level,int* pre,int pn,int mid,int* suf,int sn){if(sn>0)return make_deep(c,level,pre,pn,mid,suf,sn);View v=view_right(c,level+1,mid);if(!v.found)return from_items(c,level,pre,pn);Node n=c.nodes[v.item-NODE_BASE];return make_deep(c,level,pre,pn,v.tree,&n.child[0],n.arity);}
fn int group_items(Ctx* c,int level,int* items,int n,int* out){int used=0,pos=0;while(pos<n){int rem=n-pos,take=(rem==2||rem==4)?2:3;if(rem==1){c.failed=1;return used;}out[used]=make_node(c,level,&items[pos],take);used+=1;pos+=take;}return used;}
fn int append3(Ctx* c,int level,int left,int* bridge,int bn,int right){Tree a=c.trees[left],b=c.trees[right];if(a.kind==0){int out=right;for(int i=bn-1;i>=0;i-=1)out=cons(c,level,bridge[i],out);return out;}if(b.kind==0){int out=left;for(int i=0;i<bn;i+=1)out=snoc(c,level,out,bridge[i]);return out;}if(a.kind==1){int out=right;for(int i=bn-1;i>=0;i-=1)out=cons(c,level,bridge[i],out);return cons(c,level,a.pre[0],out);}if(b.kind==1){int out=left;for(int i=0;i<bn;i+=1)out=snoc(c,level,out,bridge[i]);return snoc(c,level,out,b.pre[0]);}int[16] all;int cn=0;for(int i=0;i<a.slen;i+=1){all[cn]=a.suf[i];cn+=1;}for(int i=0;i<bn;i+=1){all[cn]=bridge[i];cn+=1;}for(int i=0;i<b.plen;i+=1){all[cn]=b.pre[i];cn+=1;}int[8] nodes;int nn=group_items(c,level,&all[0],cn,&nodes[0]);int middle=append3(c,level+1,a.mid,&nodes[0],nn,b.mid);return make_deep(c,level,&a.pre[0],a.plen,middle,&b.suf[0],b.slen);}
fn bool pred(int mode,long target,Measure m){return mode==0?m.count>target:m.sum>=target;}
fn Split split_tree(Ctx* c,int id,Measure acc,int mode,long target){Tree t=c.trees[id];if(t.kind==0)return Split{false,0,id,empty_tree(c,t.level)};if(t.kind==1){Measure m=madd(acc,ref_measure(c,t.pre[0]));if(pred(mode,target,m))return Split{true,t.pre[0],empty_tree(c,t.level),empty_tree(c,t.level)};return Split{false,0,id,empty_tree(c,t.level)};}int[4] pi;int pn=0;Measure cur=acc;for(int i=0;i<t.plen;i+=1){cur=madd(cur,ref_measure(c,t.pre[i]));pi[pn]=t.pre[i];pn+=1;if(pred(mode,target,cur)){int l=from_items(c,t.level,&pi[0],pn-1);int r=deep_left(c,t.level,&t.pre[pn],t.plen-pn,t.mid,&t.suf[0],t.slen);return Split{true,t.pre[i],l,r};}}Measure prefix=acc;for(int i=0;i<t.plen;i+=1)prefix=madd(prefix,ref_measure(c,t.pre[i]));Measure mid=madd(prefix,tree_measure(c,t.mid));if(pred(mode,target,mid)){Split sm=split_tree(c,t.mid,prefix,mode,target);if(!sm.found){c.failed=1;return Split{false,0,id,empty_tree(c,t.level)};}Node nd=c.nodes[sm.item-NODE_BASE];Measure ca=madd(prefix,tree_measure(c,sm.left));int[3] before,after;int nb=0,na=0,pivot=0;bool found=false;for(int i=0;i<nd.arity;i+=1){Measure next=madd(ca,ref_measure(c,nd.child[i]));if(!found&&pred(mode,target,next)){pivot=nd.child[i];found=true;}else if(!found){before[nb]=nd.child[i];nb+=1;ca=next;}else{after[na]=nd.child[i];na+=1;}}if(!found){c.failed=1;return Split{false,0,id,empty_tree(c,t.level)};}int l=deep_right(c,t.level,&t.pre[0],t.plen,sm.left,&before[0],nb);int r=deep_left(c,t.level,&after[0],na,sm.right,&t.suf[0],t.slen);return Split{true,pivot,l,r};}cur=mid;int[4] si;int sn=0;for(int i=0;i<t.slen;i+=1){cur=madd(cur,ref_measure(c,t.suf[i]));si[sn]=t.suf[i];sn+=1;if(pred(mode,target,cur)){int l=deep_right(c,t.level,&t.pre[0],t.plen,t.mid,&si[0],sn-1);int r=from_items(c,t.level,&t.suf[sn],t.slen-sn);return Split{true,t.suf[i],l,r};}}return Split{false,0,id,empty_tree(c,t.level)};}
fn long item_value(int item){return (long)(-item-1);}
fn void put64(char* out,usz off,long v){ulong bits=(ulong)v;for(usz i=0;i<8;i+=1){out[off+i]=(char)(bits&255ul);bits>>=8;}}

fn long measured_finger_tree_sequence(long* input,usz length,char* output,usz capacity) @export("measured_finger_tree_sequence") {
    if(input==null||length<2||length>MAX_PARSEABLE)return -1;long n0=input[0];if(n0<0||n0>32)return -1;int n=(int)n0;if(length<(usz)(n+2))return -1;long qv=input[n+1];if(qv<1||qv>32)return -1;int q=(int)qv;if(length!=(usz)(n+2+5*q)||length>MAX_INPUT)return -1;
    Ctx c; c.nt=0;c.nn=0;c.used=0;c.failed=0;for(int i=0;i<MAX_LEVELS;i+=1)c.empty_ready[i]=false;Root[MAX_ROOTS] roots;int nr=1;int tree=empty_tree(&c,0);for(int i=0;i<n;i+=1){long v=input[1+i];if(v<0||v>MAX_VALUE)return -1;tree=snoc(&c,0,tree,(int)(-v-1));}if(c.failed)return -1;Measure im=tree_measure(&c,tree);if(im.count>64||im.sum>MAX_SUM)return -1;roots[0]=Root{tree,im.count,im.sum};long[MAX_Q*7] records;usz curi=(usz)(n+2);
    for(int op=0;op<q;op+=1){long tag=input[curi],aa=input[curi+1],bb=input[curi+2],x=input[curi+3],y=input[curi+4];curi+=5;if(tag<0||tag>6||aa<0||aa>=nr||nr>=MAX_ROOTS)return -1;int a=(int)aa,first=roots[a].tree,second=-1,result=0,result2=0;long aux=-1;bool two=false;
        if(tag==0||tag==1){if(bb!=-1||y!=-1||x<0||x>MAX_VALUE||roots[a].length>=64||roots[a].sum+x>MAX_SUM)return -1;int item=(int)(-x-1);result=tag==0?cons(&c,0,item,first):snoc(&c,0,first,item);}
        else if(tag==2||tag==3){if(bb!=-1||x!=-1||y!=-1||roots[a].length==0)return -1;View v=tag==2?view_left(&c,0,first):view_right(&c,0,first);if(!v.found)return -1;result=v.tree;aux=item_value(v.item);}
        else if(tag==4){if(bb<0||bb>=nr||x!=-1||y!=-1)return -1;int b=(int)bb;if(roots[a].length+roots[b].length>64||roots[a].sum+roots[b].sum>MAX_SUM)return -1;result=append3(&c,0,first,null,0,roots[b].tree);}
        else {if(bb!=-1||y!=-1)return -1;int mode=tag==5?0:1;if((tag==5&&(x<0||x>roots[a].length))||(tag==6&&(x<1||x>MAX_SUM)))return -1;Split s=split_tree(&c,first,Measure{0,0},mode,x);if(s.found){if(tag==5){result=s.left;result2=cons(&c,0,s.item,s.right);aux=x;}else{result=snoc(&c,0,s.left,s.item);result2=s.right;aux=(long)tree_measure(&c,result).count;}}else{result=first;result2=empty_tree(&c,0);aux=tag==5?x:-1;}two=true;}
        if(c.failed)return -1;Measure m1=tree_measure(&c,result);if(m1.count>64||m1.sum>MAX_SUM)return -1;int left_id=nr;roots[nr]=Root{result,m1.count,m1.sum};nr+=1;int right_len=-1;long right_sum=-1;if(two){Measure m2=tree_measure(&c,result2);if(m2.count>64||m2.sum>MAX_SUM||nr>=MAX_ROOTS)return -1;second=nr;roots[nr]=Root{result2,m2.count,m2.sum};nr+=1;right_len=m2.count;right_sum=m2.sum;}int z=7*op;records[z]=left_id;records[z+1]=m1.count;records[z+2]=m1.sum;records[z+3]=second;records[z+4]=right_len;records[z+5]=right_sum;records[z+6]=aux;
    }
    usz bytes=(usz)(56*q);if(output==null||capacity<bytes)return -2;for(usz i=0;i<(usz)(7*q);i+=1)put64(output,8*i,records[i]);return (long)bytes;
}
