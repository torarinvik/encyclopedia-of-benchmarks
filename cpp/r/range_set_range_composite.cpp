#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t NMAX=64,QMAX=32,TREE_N=4*NMAX+5;
constexpr std::int64_t MOD=998244353;
struct Affine{std::int64_t a,b;};
struct Node{std::int64_t a=0,b=0,lazy_a=0,lazy_b=0;bool has=false;};
struct Operation{int type;std::int64_t left,right,x,y;};
Affine compose(Affine after,Affine before){return {after.a*before.a%MOD,(after.a*before.b+after.b)%MOD};}
Affine power_map(std::int64_t a,std::int64_t b,std::size_t exponent){Affine result{1,0},base{a,b};while(exponent){if(exponent&1)result=compose(base,result);base=compose(base,base);exponent>>=1;}return result;}
void build(Node*t,std::size_t node,std::size_t l,std::size_t r,const std::int64_t*a,const std::int64_t*b){if(r-l==1){t[node].a=a[l];t[node].b=b[l];return;}auto m=l+(r-l)/2;build(t,node*2,l,m,a,b);build(t,node*2+1,m,r,a,b);auto z=compose({t[node*2+1].a,t[node*2+1].b},{t[node*2].a,t[node*2].b});t[node].a=z.a;t[node].b=z.b;}
void apply(Node*t,std::size_t v,std::size_t l,std::size_t r,std::int64_t a,std::int64_t b){auto z=power_map(a,b,r-l);t[v].a=z.a;t[v].b=z.b;t[v].lazy_a=a;t[v].lazy_b=b;t[v].has=true;}
void push(Node*t,std::size_t v,std::size_t l,std::size_t r){if(!t[v].has||r-l==1)return;auto m=l+(r-l)/2;apply(t,v*2,l,m,t[v].lazy_a,t[v].lazy_b);apply(t,v*2+1,m,r,t[v].lazy_a,t[v].lazy_b);t[v].has=false;}
void update(Node*t,std::size_t v,std::size_t l,std::size_t r,std::size_t ql,std::size_t qr,std::int64_t a,std::int64_t b){if(ql<=l&&r<=qr){apply(t,v,l,r,a,b);return;}push(t,v,l,r);auto m=l+(r-l)/2;if(ql<m)update(t,v*2,l,m,ql,qr,a,b);if(qr>m)update(t,v*2+1,m,r,ql,qr,a,b);auto z=compose({t[v*2+1].a,t[v*2+1].b},{t[v*2].a,t[v*2].b});t[v].a=z.a;t[v].b=z.b;}
Affine query(Node*t,std::size_t v,std::size_t l,std::size_t r,std::size_t ql,std::size_t qr){if(ql<=l&&r<=qr)return {t[v].a,t[v].b};push(t,v,l,r);auto m=l+(r-l)/2;if(qr<=m)return query(t,v*2,l,m,ql,qr);if(ql>=m)return query(t,v*2+1,m,r,ql,qr);return compose(query(t,v*2+1,m,r,ql,qr),query(t,v*2,l,m,ql,qr));}
void put(std::uint8_t*out,std::size_t at,std::int64_t x){auto bits=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;++b)out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t range_set_range_composite(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
    if(!input||length<2||length>291)return -1;auto n64=input[0],q64=input[1];if(n64<1||n64>64||q64<1||q64>32)return -1;auto n=static_cast<std::size_t>(n64),q=static_cast<std::size_t>(q64),off=std::size_t(2);if(length<2+2*n)return -1;
    std::int64_t ia[NMAX],ib[NMAX];for(std::size_t i=0;i<n;++i){ia[i]=input[off++];ib[i]=input[off++];if(ia[i]<1||ia[i]>=MOD||ib[i]<0||ib[i]>=MOD)return -1;}
    Operation ops[QMAX];std::size_t answer_count=0;for(std::size_t k=0;k<q;++k){if(off>=length)return -1;auto type=input[off++];if(type==0){if(off+4>length)return -1;auto l=input[off++],r=input[off++],a=input[off++],b=input[off++];if(l<0||l>=r||r>n64||a<1||a>=MOD||b<0||b>=MOD)return -1;ops[k]={0,l,r,a,b};}else if(type==1){if(off+3>length)return -1;auto l=input[off++],r=input[off++],x=input[off++];if(l<0||l>=r||r>n64||x<0||x>=MOD)return -1;ops[k]={1,l,r,x,0};++answer_count;}else return -1;}
    if(off!=length)return -1;Node tree[TREE_N]{};build(tree,1,0,n,ia,ib);std::int64_t ans[QMAX];std::size_t count=0;for(std::size_t k=0;k<q;++k){auto op=ops[k];if(op.type==0)update(tree,1,0,n,op.left,op.right,op.x,op.y);else{auto z=query(tree,1,0,n,op.left,op.right);ans[count++]=(z.a*op.x+z.b)%MOD;}}
    auto bytes=8*answer_count;if(!output||capacity<bytes)return -2;for(std::size_t i=0;i<answer_count;++i)put(output,8*i,ans[i]);return static_cast<std::int64_t>(bytes);
}
