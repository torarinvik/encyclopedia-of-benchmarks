#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 32
#define TREE_N (4 * MAX_N + 5)
#define MOD INT64_C(998244353)
typedef struct { int64_t a, b; } Affine;
typedef struct { int64_t a,b,lazy_a,lazy_b; int has_lazy; } Node;
typedef struct { int type; int64_t left,right,x,y; } Operation;

static Affine compose(Affine after, Affine before) {
    return (Affine){after.a*before.a%MOD,(after.a*before.b+after.b)%MOD};
}
static Affine power_map(int64_t a,int64_t b,size_t exponent) {
    Affine result={1,0},base={a,b};
    while(exponent){if(exponent&1)result=compose(base,result);base=compose(base,base);exponent>>=1;}
    return result;
}
static void build(Node *tree,size_t node,size_t left,size_t right,const int64_t *a,const int64_t *b) {
    if(right-left==1){tree[node].a=a[left];tree[node].b=b[left];return;}
    size_t mid=left+(right-left)/2;build(tree,node*2,left,mid,a,b);build(tree,node*2+1,mid,right,a,b);
    Affine x={tree[node*2].a,tree[node*2].b},y={tree[node*2+1].a,tree[node*2+1].b};Affine z=compose(y,x);tree[node].a=z.a;tree[node].b=z.b;
}
static void apply(Node *tree,size_t node,size_t left,size_t right,int64_t a,int64_t b) {
    Affine z=power_map(a,b,right-left);tree[node].a=z.a;tree[node].b=z.b;tree[node].lazy_a=a;tree[node].lazy_b=b;tree[node].has_lazy=1;
}
static void push(Node *tree,size_t node,size_t left,size_t right) {
    if(!tree[node].has_lazy||right-left==1)return;size_t mid=left+(right-left)/2;
    apply(tree,node*2,left,mid,tree[node].lazy_a,tree[node].lazy_b);apply(tree,node*2+1,mid,right,tree[node].lazy_a,tree[node].lazy_b);tree[node].has_lazy=0;
}
static void update(Node *tree,size_t node,size_t left,size_t right,size_t ql,size_t qr,int64_t a,int64_t b) {
    if(ql<=left&&right<=qr){apply(tree,node,left,right,a,b);return;}push(tree,node,left,right);size_t mid=left+(right-left)/2;
    if(ql<mid)update(tree,node*2,left,mid,ql,qr,a,b);if(qr>mid)update(tree,node*2+1,mid,right,ql,qr,a,b);
    Affine x={tree[node*2].a,tree[node*2].b},y={tree[node*2+1].a,tree[node*2+1].b};Affine z=compose(y,x);tree[node].a=z.a;tree[node].b=z.b;
}
static Affine query(Node *tree,size_t node,size_t left,size_t right,size_t ql,size_t qr) {
    if(ql<=left&&right<=qr)return (Affine){tree[node].a,tree[node].b};push(tree,node,left,right);size_t mid=left+(right-left)/2;
    if(qr<=mid)return query(tree,node*2,left,mid,ql,qr);if(ql>=mid)return query(tree,node*2+1,mid,right,ql,qr);
    Affine x=query(tree,node*2,left,mid,ql,qr),y=query(tree,node*2+1,mid,right,ql,qr);return compose(y,x);
}
static void write_i64_le(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b)out[at+b]=(uint8_t)(bits>>(8*b));}

int64_t range_set_range_composite(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<2||length>291)return -1;int64_t n64=input[0],q64=input[1];if(n64<1||n64>MAX_N||q64<1||q64>MAX_Q)return -1;
    size_t n=(size_t)n64,q=(size_t)q64,off=2;int64_t init_a[MAX_N],init_b[MAX_N];
    if(length<2+2*n)return -1;for(size_t i=0;i<n;++i){init_a[i]=input[off++];init_b[i]=input[off++];if(init_a[i]<1||init_a[i]>=MOD||init_b[i]<0||init_b[i]>=MOD)return -1;}
    Operation ops[MAX_Q];size_t answer_count=0;
    for(size_t k=0;k<q;++k){if(off>=length)return -1;int64_t type=input[off++];if(type==0){if(off+4>length)return -1;int64_t l=input[off++],r=input[off++],a=input[off++],b=input[off++];if(l<0||l>=r||r>n64||a<1||a>=MOD||b<0||b>=MOD)return -1;ops[k]=(Operation){0,l,r,a,b};}
        else if(type==1){if(off+3>length)return -1;int64_t l=input[off++],r=input[off++],x=input[off++];if(l<0||l>=r||r>n64||x<0||x>=MOD)return -1;ops[k]=(Operation){1,l,r,x,0};++answer_count;}else return -1;}
    if(off!=length)return -1;
    Node tree[TREE_N]={0};build(tree,1,0,n,init_a,init_b);int64_t answers[MAX_Q];size_t out_count=0;
    for(size_t k=0;k<q;++k){Operation op=ops[k];if(op.type==0)update(tree,1,0,n,(size_t)op.left,(size_t)op.right,op.x,op.y);else{Affine z=query(tree,1,0,n,(size_t)op.left,(size_t)op.right);answers[out_count++]=(z.a*op.x+z.b)%MOD;}}
    size_t bytes=8*answer_count;if(!output||capacity<bytes)return -2;for(size_t i=0;i<answer_count;++i)write_i64_le(output,8*i,answers[i]);return (int64_t)bytes;
}
