#include <stddef.h>
#include <stdint.h>

#define FT_MAX_Q 32u
#define FT_MAX_ROOTS (1u + 2u * FT_MAX_Q)
#define FT_ARENA 16384u
#define FT_LEVELS 16u
#define FT_MAX_INPUT 194u
#define FT_MAX_PARSEABLE 195u
#define FT_MAX_VALUE INT64_C(1000000)
#define FT_MAX_LENGTH 64
#define FT_MAX_SUM INT64_C(64000000)
#define FT_MAX_BRIDGE 16u

typedef struct { int32_t count; int64_t sum; } measure_t;
typedef struct {
    uint8_t kind, level, plen, slen;
    int32_t mid;
    int32_t pre[4], suf[4];
    int32_t count;
    int64_t sum;
} tree_t;
typedef struct {
    uint8_t kind, level, arity;
    int32_t child[3];
    int32_t count;
    int64_t sum;
} node_t;
typedef union { tree_t tree; node_t node; } object_data_t;
typedef struct { object_data_t data; } object_t;
typedef struct {
    object_t arena[FT_ARENA];
    size_t used;
    int32_t empty_id[FT_LEVELS];
    uint8_t empty_ready[FT_LEVELS];
    int failed;
} ft_context_t;
typedef struct { int32_t tree; int32_t length; int64_t sum; } root_t;
typedef struct { int found; int32_t item,left,right; } split_t;
typedef struct { int found; int32_t item,tree; } view_t;

static measure_t zero_measure(void) { return (measure_t){0,0}; }
static measure_t ref_measure(const ft_context_t *c, int32_t ref)
{
    if (ref < 0) return (measure_t){1, (int64_t)(-ref - 1)};
    const node_t *n = &c->arena[(size_t)ref].data.node;
    return (measure_t){n->count,n->sum};
}
static measure_t tree_measure(const ft_context_t *c, int32_t id)
{
    const tree_t *t = &c->arena[(size_t)id].data.tree;
    return (measure_t){t->count,t->sum};
}
static measure_t measure_add(measure_t a, measure_t b)
{
    return (measure_t){a.count+b.count,a.sum+b.sum};
}
static int32_t alloc_object(ft_context_t *c, int is_tree)
{
    if (c->used >= FT_ARENA) { c->failed=1; return 0; }
    size_t id=c->used++;
    (void)is_tree;
    return (int32_t)id;
}
static int32_t empty_tree(ft_context_t *c, uint8_t level)
{
    if (level >= FT_LEVELS) { c->failed=1; return 0; }
    if (c->empty_ready[level]) return c->empty_id[level];
    int32_t id=alloc_object(c,1);
    tree_t *t=&c->arena[(size_t)id].data.tree;
    *t=(tree_t){0}; t->kind=0; t->level=level; t->mid=-1;
    c->empty_id[level]=id; c->empty_ready[level]=1;
    return id;
}
static int32_t make_node(ft_context_t *c, uint8_t child_level, const int32_t *items, uint8_t n)
{
    int32_t id=alloc_object(c,0); node_t *out=&c->arena[(size_t)id].data.node;
    *out=(node_t){0}; out->kind=1; out->level=(uint8_t)(child_level+1); out->arity=n;
    measure_t m=zero_measure();
    for (uint8_t i=0;i<n;i++) { out->child[i]=items[i]; m=measure_add(m,ref_measure(c,items[i])); }
    out->count=m.count; out->sum=m.sum;
    return id;
}
static int32_t make_single(ft_context_t *c, uint8_t level, int32_t item)
{
    int32_t id=alloc_object(c,1); tree_t *t=&c->arena[(size_t)id].data.tree;
    *t=(tree_t){0}; t->kind=1; t->level=level; t->pre[0]=item; t->plen=1;
    measure_t m=ref_measure(c,item); t->count=m.count; t->sum=m.sum;
    return id;
}
static int32_t make_deep(ft_context_t *c, uint8_t level, const int32_t *pre, uint8_t pn,
                         int32_t mid, const int32_t *suf, uint8_t sn)
{
    if (!pn || !sn) { c->failed=1; return empty_tree(c,level); }
    int32_t id=alloc_object(c,1); tree_t *t=&c->arena[(size_t)id].data.tree;
    *t=(tree_t){0}; t->kind=2; t->level=level; t->plen=pn; t->slen=sn; t->mid=mid;
    measure_t m=tree_measure(c,mid);
    for (uint8_t i=0;i<pn;i++) { t->pre[i]=pre[i]; m=measure_add(m,ref_measure(c,pre[i])); }
    for (uint8_t i=0;i<sn;i++) { t->suf[i]=suf[i]; m=measure_add(m,ref_measure(c,suf[i])); }
    t->count=m.count; t->sum=m.sum;
    return id;
}
static int32_t cons(ft_context_t *c, uint8_t level, int32_t item, int32_t id);
static int32_t snoc(ft_context_t *c, uint8_t level, int32_t id, int32_t item);
static int32_t from_items(ft_context_t *c, uint8_t level, const int32_t *items, uint8_t n)
{
    int32_t out=empty_tree(c,level);
    for (uint8_t i=0;i<n;i++) out=snoc(c,level,out,items[i]);
    return out;
}
static int32_t cons(ft_context_t *c, uint8_t level, int32_t item, int32_t id)
{
    tree_t t=c->arena[(size_t)id].data.tree;
    if (t.kind==0) return make_single(c,level,item);
    if (t.kind==1) { int32_t p[1]={item},s[1]={t.pre[0]}; return make_deep(c,level,p,1,empty_tree(c,(uint8_t)(level+1)),s,1); }
    if (t.plen<4) { int32_t p[4]; p[0]=item; for(uint8_t i=0;i<t.plen;i++)p[i+1]=t.pre[i]; return make_deep(c,level,p,(uint8_t)(t.plen+1),t.mid,t.suf,t.slen); }
    int32_t group[3]={t.pre[1],t.pre[2],t.pre[3]};
    int32_t middle=cons(c,(uint8_t)(level+1),make_node(c,level,group,3),t.mid);
    int32_t p[2]={item,t.pre[0]};
    return make_deep(c,level,p,2,middle,t.suf,t.slen);
}
static int32_t snoc(ft_context_t *c, uint8_t level, int32_t id, int32_t item)
{
    tree_t t=c->arena[(size_t)id].data.tree;
    if (t.kind==0) return make_single(c,level,item);
    if (t.kind==1) { int32_t p[1]={t.pre[0]},s[1]={item}; return make_deep(c,level,p,1,empty_tree(c,(uint8_t)(level+1)),s,1); }
    if (t.slen<4) { int32_t s[4]; for(uint8_t i=0;i<t.slen;i++)s[i]=t.suf[i]; s[t.slen]=item; return make_deep(c,level,t.pre,t.plen,t.mid,s,(uint8_t)(t.slen+1)); }
    int32_t group[3]={t.suf[0],t.suf[1],t.suf[2]};
    int32_t middle=snoc(c,(uint8_t)(level+1),t.mid,make_node(c,level,group,3));
    int32_t s[2]={t.suf[3],item};
    return make_deep(c,level,t.pre,t.plen,middle,s,2);
}
static view_t view_left(ft_context_t *c, uint8_t level, int32_t id)
{
    tree_t t=c->arena[(size_t)id].data.tree;
    if (t.kind==0) return (view_t){0,0,id};
    if (t.kind==1) return (view_t){1,t.pre[0],empty_tree(c,level)};
    int32_t item=t.pre[0], rest;
    if (t.plen>1) rest=make_deep(c,level,t.pre+1,(uint8_t)(t.plen-1),t.mid,t.suf,t.slen);
    else {
        view_t mv=view_left(c,(uint8_t)(level+1),t.mid);
        if (!mv.found) rest=from_items(c,level,t.suf,t.slen);
        else {
            node_t node=c->arena[(size_t)mv.item].data.node;
            rest=make_deep(c,level,node.child,node.arity,mv.tree,t.suf,t.slen);
        }
    }
    return (view_t){1,item,rest};
}
static view_t view_right(ft_context_t *c, uint8_t level, int32_t id)
{
    tree_t t=c->arena[(size_t)id].data.tree;
    if (t.kind==0) return (view_t){0,0,id};
    if (t.kind==1) return (view_t){1,t.pre[0],empty_tree(c,level)};
    int32_t item=t.suf[t.slen-1], rest;
    if (t.slen>1) rest=make_deep(c,level,t.pre,t.plen,t.mid,t.suf,(uint8_t)(t.slen-1));
    else {
        view_t mv=view_right(c,(uint8_t)(level+1),t.mid);
        if (!mv.found) rest=from_items(c,level,t.pre,t.plen);
        else {
            node_t node=c->arena[(size_t)mv.item].data.node;
            rest=make_deep(c,level,t.pre,t.plen,mv.tree,node.child,node.arity);
        }
    }
    return (view_t){1,item,rest};
}
static int32_t deep_left(ft_context_t *c, uint8_t level, const int32_t *pre, uint8_t pn,
                         int32_t mid, const int32_t *suf, uint8_t sn)
{
    if (pn) return make_deep(c,level,pre,pn,mid,suf,sn);
    view_t v=view_left(c,(uint8_t)(level+1),mid);
    if (!v.found) return from_items(c,level,suf,sn);
    node_t node=c->arena[(size_t)v.item].data.node;
    return make_deep(c,level,node.child,node.arity,v.tree,suf,sn);
}
static int32_t deep_right(ft_context_t *c, uint8_t level, const int32_t *pre, uint8_t pn,
                          int32_t mid, const int32_t *suf, uint8_t sn)
{
    if (sn) return make_deep(c,level,pre,pn,mid,suf,sn);
    view_t v=view_right(c,(uint8_t)(level+1),mid);
    if (!v.found) return from_items(c,level,pre,pn);
    node_t node=c->arena[(size_t)v.item].data.node;
    return make_deep(c,level,pre,pn,v.tree,node.child,node.arity);
}
static uint8_t group_items(ft_context_t *c, uint8_t level, const int32_t *items, uint8_t n,
                           int32_t *out)
{
    uint8_t used=0, pos=0;
    while (pos<n) {
        uint8_t rem=(uint8_t)(n-pos), take;
        if (rem==2 || rem==4) take=2; else take=3;
        if (rem==1) { c->failed=1; return used; }
        out[used++]=make_node(c,level,items+pos,take);
        pos=(uint8_t)(pos+take);
    }
    return used;
}
static int32_t append3(ft_context_t *c, uint8_t level, int32_t left,
                       const int32_t *bridge, uint8_t bn, int32_t right)
{
    tree_t a=c->arena[(size_t)left].data.tree, b=c->arena[(size_t)right].data.tree;
    if (a.kind==0) { int32_t out=right; for(int i=(int)bn-1;i>=0;i--)out=cons(c,level,bridge[i],out); return out; }
    if (b.kind==0) { int32_t out=left; for(uint8_t i=0;i<bn;i++)out=snoc(c,level,out,bridge[i]); return out; }
    if (a.kind==1) { int32_t out=right; for(int i=(int)bn-1;i>=0;i--)out=cons(c,level,bridge[i],out); return cons(c,level,a.pre[0],out); }
    if (b.kind==1) { int32_t out=left; for(uint8_t i=0;i<bn;i++)out=snoc(c,level,out,bridge[i]); return snoc(c,level,out,b.pre[0]); }
    int32_t combined[16]; uint8_t cn=0;
    for(uint8_t i=0;i<a.slen;i++)combined[cn++]=a.suf[i];
    for(uint8_t i=0;i<bn;i++)combined[cn++]=bridge[i];
    for(uint8_t i=0;i<b.plen;i++)combined[cn++]=b.pre[i];
    int32_t nodes[8]; uint8_t nn=group_items(c,level,combined,cn,nodes);
    int32_t middle=append3(c,(uint8_t)(level+1),a.mid,nodes,nn,b.mid);
    return make_deep(c,level,a.pre,a.plen,middle,b.suf,b.slen);
}
static int predicate(int mode, int64_t target, measure_t m)
{ return mode==0 ? m.count>target : m.sum>=target; }
static split_t split_tree(ft_context_t *c, int32_t id, measure_t acc, int mode, int64_t target)
{
    tree_t t=c->arena[(size_t)id].data.tree;
    if (!t.kind) return (split_t){0,0,0,id};
    if (t.kind==1) {
        measure_t m=measure_add(acc,ref_measure(c,t.pre[0]));
        if (predicate(mode,target,m)) return (split_t){1,t.pre[0],empty_tree(c,t.level),empty_tree(c,t.level)};
        return (split_t){0,0,id,empty_tree(c,t.level)};
    }
    int32_t pref_items[4]; uint8_t pn=0; measure_t cur=acc;
    for(uint8_t i=0;i<t.plen;i++){
        cur=measure_add(cur,ref_measure(c,t.pre[i])); pref_items[pn++]=t.pre[i];
        if(predicate(mode,target,cur)){
            int32_t l=from_items(c,t.level,pref_items,(uint8_t)(pn-1));
            int32_t r=deep_left(c,t.level,t.pre+pn,(uint8_t)(t.plen-pn),t.mid,t.suf,t.slen);
            return (split_t){1,t.pre[i],l,r};
        }
    }
    measure_t after_prefix=measure_add(acc,(measure_t){0,0});
    tree_t *mt=&c->arena[(size_t)t.mid].data.tree;
    after_prefix=measure_add(after_prefix,(measure_t){0,0});
    for(uint8_t i=0;i<t.plen;i++)after_prefix=measure_add(after_prefix,ref_measure(c,t.pre[i]));
    measure_t through_mid=measure_add(after_prefix,(measure_t){mt->count,mt->sum});
    if(predicate(mode,target,through_mid)){
        split_t sm=split_tree(c,t.mid,after_prefix,mode,target);
        if(!sm.found){c->failed=1;return (split_t){0,0,id,empty_tree(c,t.level)};}
        node_t node=c->arena[(size_t)sm.item].data.node;
        measure_t child_acc=measure_add(after_prefix,tree_measure(c,sm.left));
        int32_t before[3];uint8_t nb=0;int32_t pivot=0;int32_t after[3];uint8_t na=0;int found=0;
        for(uint8_t i=0;i<node.arity;i++){
            measure_t next=measure_add(child_acc,ref_measure(c,node.child[i]));
            if(!found&&predicate(mode,target,next)){pivot=node.child[i];found=1;}
            else if(!found){before[nb++]=node.child[i];child_acc=next;}
            else after[na++]=node.child[i];
        }
        if(!found){c->failed=1;return (split_t){0,0,id,empty_tree(c,t.level)};}
        int32_t l=deep_right(c,t.level,t.pre,t.plen,sm.left,before,nb);
        int32_t r=deep_left(c,t.level,after,na,sm.right,t.suf,t.slen);
        return (split_t){1,pivot,l,r};
    }
    cur=through_mid; int32_t suffix_items[4];uint8_t sn=0;
    for(uint8_t i=0;i<t.slen;i++){
        cur=measure_add(cur,ref_measure(c,t.suf[i]));suffix_items[sn++]=t.suf[i];
        if(predicate(mode,target,cur)){
            int32_t l=deep_right(c,t.level,t.pre,t.plen,t.mid,suffix_items,(uint8_t)(sn-1));
            int32_t r=from_items(c,t.level,t.suf+sn,(uint8_t)(t.slen-sn));
            return (split_t){1,t.suf[i],l,r};
        }
    }
    return (split_t){0,0,id,empty_tree(c,t.level)};
}
static int64_t item_value(int32_t item) { return (int64_t)(-item-1); }
static void store_i64(uint8_t *out,size_t offset,int64_t v)
{ uint64_t bits=(uint64_t)v;for(size_t i=0;i<8;i++)out[offset+i]=(uint8_t)(bits>>(8*i)); }

int64_t measured_finger_tree_sequence(const int64_t *input,size_t length,uint8_t *output,size_t capacity)
{
    if(!input||length<2||length>FT_MAX_PARSEABLE)return -1;
    int64_t n0=input[0];if(n0<0||n0>32)return -1;size_t n=(size_t)n0;
    if(length<n+2)return -1;
    int64_t qv=input[n+1];if(qv<1||qv>32)return -1;size_t q=(size_t)qv;
    if(length!=n+2+5*q||length>FT_MAX_INPUT)return -1;
    ft_context_t c={0};root_t roots[FT_MAX_ROOTS];size_t nr=1;
    int32_t tree=empty_tree(&c,0);
    for(size_t i=0;i<n;i++){int64_t v=input[1+i];if(v<0||v>FT_MAX_VALUE)return -1;tree=snoc(&c,0,tree,(int32_t)(-v-1));}
    if(c.failed)return -1;
    measure_t im=tree_measure(&c,tree);if(im.count>FT_MAX_LENGTH||im.sum>FT_MAX_SUM)return -1;
    roots[0]=(root_t){tree,im.count,im.sum};
    int64_t records[FT_MAX_Q][7];size_t cursor=n+2;
    for(size_t op=0;op<q;op++){
        int64_t tag=input[cursor],aa=input[cursor+1],bb=input[cursor+2],x=input[cursor+3],y=input[cursor+4];cursor+=5;
        if(tag<0||tag>6||aa<0||(uint64_t)aa>=nr||nr>=FT_MAX_ROOTS)return -1;
        size_t a=(size_t)aa;int32_t first=roots[a].tree,left_id;int32_t second=-1;int64_t aux=-1;
        int32_t result=0,result2=0;int two=0;
        if(tag==0||tag==1){
            if(bb!=-1||y!=-1||x<0||x>FT_MAX_VALUE||roots[a].length>=FT_MAX_LENGTH||roots[a].sum+x>FT_MAX_SUM)return -1;
            int32_t item=(int32_t)(-x-1);result=tag==0?cons(&c,0,item,first):snoc(&c,0,first,item);
        }else if(tag==2||tag==3){
            if(bb!=-1||x!=-1||y!=-1||roots[a].length==0)return -1;
            view_t v=tag==2?view_left(&c,0,first):view_right(&c,0,first);
            if(!v.found)return -1;result=v.tree;aux=item_value(v.item);
        }else if(tag==4){
            if(bb<0||(uint64_t)bb>=nr||x!=-1||y!=-1)return -1;
            if((int64_t)roots[a].length+roots[(size_t)bb].length>FT_MAX_LENGTH||roots[a].sum+roots[(size_t)bb].sum>FT_MAX_SUM)return -1;
            result=append3(&c,0,first,NULL,0,roots[(size_t)bb].tree);
        }else if(tag==5||tag==6){
            if(bb!=-1||y!=-1)return -1;
            int mode=tag==5?0:1;
            if((tag==5&&(x<0||x>roots[a].length))||(tag==6&&(x<1||x>FT_MAX_SUM)))return -1;
            split_t s=split_tree(&c,first,zero_measure(),mode,x);
            if(s.found){
                if(tag==5){result=s.left;result2=cons(&c,0,s.item,s.right);aux=x;}
                else{result=snoc(&c,0,s.left,s.item);result2=s.right;aux=tree_measure(&c,result).count;}
            }
            else{result=first;result2=empty_tree(&c,0);aux=tag==5?x:-1;}
            two=1;
        }
        if(c.failed)return -1;
        measure_t m1=tree_measure(&c,result);if(m1.count>FT_MAX_LENGTH||m1.sum>FT_MAX_SUM)return -1;
        left_id=(int32_t)nr;roots[nr++]=(root_t){result,m1.count,m1.sum};
        int32_t right_len=-1;int64_t right_sum=-1;
        if(two){measure_t m2=tree_measure(&c,result2);if(m2.count>FT_MAX_LENGTH||m2.sum>FT_MAX_SUM||nr>=FT_MAX_ROOTS)return -1;second=(int32_t)nr;roots[nr++]=(root_t){result2,m2.count,m2.sum};right_len=m2.count;right_sum=m2.sum;}
        records[op][0]=left_id;records[op][1]=m1.count;records[op][2]=m1.sum;records[op][3]=second;records[op][4]=right_len;records[op][5]=right_sum;records[op][6]=aux;
    }
    size_t bytes=56*q;
    if(!output||capacity<bytes)return -2;
    uint8_t staged[1792];for(size_t i=0;i<q;i++)for(size_t j=0;j<7;j++)store_i64(staged,8*(7*i+j),records[i][j]);
    for(size_t i=0;i<bytes;i++)output[i]=staged[i];
    return (int64_t)bytes;
}
