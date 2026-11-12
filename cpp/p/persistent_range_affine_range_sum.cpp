#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MOD=998244353; constexpr std::size_t N=16,Q=16,CAP=4096;
struct Node { std::int64_t sum=0,mul=1,add=0; int left=-1,right=-1; };
struct Tree {
 std::array<Node,CAP> a{}; std::size_t used=0;
 std::int64_t norm(std::int64_t x) const { x%=MOD; return x<0?x+MOD:x; }
 int clone(int s){if(s<0||used==CAP)return -1;int d=(int)used++;a[d]=a[s];return d;}
 int make(std::int64_t sum,int l=-1,int r=-1){if(used==CAP)return -1;int d=(int)used++;a[d]={sum,1,0,l,r};return d;}
 void apply(int x,std::int64_t m,std::int64_t b,std::size_t len){m=norm(m);b=norm(b);a[x].sum=norm(m*a[x].sum+b*(std::int64_t)len);a[x].mul=norm(m*a[x].mul);a[x].add=norm(m*a[x].add+b);}
 bool push(int x,std::size_t l,std::size_t r){auto m=a[x].mul,b=a[x].add;if(m==1&&b==0)return true;if(l<r){auto mid=l+(r-l)/2;int lc=clone(a[x].left),rc=clone(a[x].right);if(lc<0||rc<0)return false;a[x].left=lc;a[x].right=rc;apply(lc,m,b,mid-l+1);apply(rc,m,b,r-mid);}a[x].mul=1;a[x].add=0;return true;}
 int build(const std::int64_t*v,std::size_t l,std::size_t r){if(l==r)return make(v[l]);auto m=l+(r-l)/2;int x=build(v,l,m),y=build(v,m+1,r);if(x<0||y<0)return -1;return make(norm(a[x].sum+a[y].sum),x,y);}
 int update(int root,std::size_t l,std::size_t r,std::size_t ql,std::size_t qr,std::int64_t m,std::int64_t b){if(ql<=l&&r<=qr){int x=clone(root);if(x<0)return -1;apply(x,m,b,r-l+1);return x;}int x=clone(root);if(x<0||!push(x,l,r))return -1;auto mid=l+(r-l)/2;if(ql<=mid){int y=update(a[x].left,l,mid,ql,qr,m,b);if(y<0)return -1;a[x].left=y;}if(qr>mid){int y=update(a[x].right,mid+1,r,ql,qr,m,b);if(y<0)return -1;a[x].right=y;}a[x].sum=norm(a[a[x].left].sum+a[a[x].right].sum);return x;}
 int logical_child(int s,bool right,std::size_t l,std::size_t r){int c=clone(right?a[s].right:a[s].left);if(c<0)return -1;auto m=a[s].mul,b=a[s].add;if(m!=1||b!=0){auto mid=l+(r-l)/2;apply(c,m,b,right?r-mid:mid-l+1);}return c;}
 int copy_range(int dst,int src,std::size_t l,std::size_t r,std::size_t ql,std::size_t qr){if(ql<=l&&r<=qr)return src;int x=clone(dst);if(x<0||!push(x,l,r))return -1;auto mid=l+(r-l)/2;if(ql<=mid){int s=logical_child(src,false,l,r);if(s<0)return -1;int y=copy_range(a[x].left,s,l,mid,ql,qr);if(y<0)return -1;a[x].left=y;}if(qr>mid){int s=logical_child(src,true,l,r);if(s<0)return -1;int y=copy_range(a[x].right,s,mid+1,r,ql,qr);if(y<0)return -1;a[x].right=y;}a[x].sum=norm(a[a[x].left].sum+a[a[x].right].sum);return x;}
 std::int64_t query(int x,std::size_t l,std::size_t r,std::size_t ql,std::size_t qr,std::int64_t cm=1,std::int64_t ca=0)const{if(ql<=l&&r<=qr)return norm(cm*a[x].sum+ca*(std::int64_t)(r-l+1));auto mid=l+(r-l)/2;auto nm=norm(cm*a[x].mul),na=norm(cm*a[x].add+ca);std::int64_t z=0;if(ql<=mid)z=query(a[x].left,l,mid,ql,qr,nm,na);if(qr>mid)z=norm(z+query(a[x].right,mid+1,r,ql,qr,nm,na));return z;}
};
bool ref_ok(std::int64_t x,std::size_t i,const std::array<std::int64_t,Q>&kind){return x==-1||(x>=0&&(std::size_t)x<i&&(kind[(std::size_t)x]==0||kind[(std::size_t)x]==1));}
void put(std::uint8_t*out,std::size_t at,std::int64_t x){auto b=(std::uint64_t)x;for(int j=0;j<8;j++)out[at+j]=(std::uint8_t)(b>>(8*j));}
}
extern "C" std::int64_t persistent_range_affine_range_sum(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){
 if(!in||len<2||len>115)return -1;auto n0=in[0],q0=in[1];if(n0<1||n0>16||q0<1||q0>16)return -1;std::size_t n=n0,q=q0,off=2+n;if(len<off)return -1;for(std::size_t j=0;j<n;j++)if(in[2+j]<0||in[2+j]>=MOD)return -1;
 std::array<std::int64_t,Q> kind{},ref{},src{},l{},r{},mul{},add{};
 for(std::size_t i=0;i<q;i++){if(off>=len)return -1;auto op=in[off];std::size_t w=op==0?6:op==1?5:op==2?4:0;if(!w||len-off<w)return -1;auto k=in[off+1];if(!ref_ok(k,i,kind))return -1;kind[i]=op;ref[i]=k;mul[i]=1;add[i]=0;if(op==0||op==2){l[i]=in[off+2];r[i]=in[off+3];if(l[i]<0||r[i]<=l[i]||r[i]>n0)return -1;}if(op==0){mul[i]=in[off+4];add[i]=in[off+5];if(mul[i]<1||mul[i]>=MOD||add[i]<0||add[i]>=MOD)return -1;}if(op==1){src[i]=in[off+2];l[i]=in[off+3];r[i]=in[off+4];if(!ref_ok(src[i],i,kind)||l[i]<0||r[i]<=l[i]||r[i]>n0)return -1;}off+=w;}
 if(off!=len)return -1;Tree t;int initial=t.build(in+2,0,n-1);if(initial<0)return -1;std::array<int,Q> roots{};std::array<std::int64_t,Q> ans{};std::size_t na=0;
 for(std::size_t i=0;i<q;i++){int base=ref[i]<0?initial:roots[(std::size_t)ref[i]];if(kind[i]==0){roots[i]=t.update(base,0,n-1,l[i],r[i]-1,mul[i],add[i]);if(roots[i]<0)return -1;}else if(kind[i]==1){int source=src[i]<0?initial:roots[(std::size_t)src[i]];roots[i]=t.copy_range(base,source,0,n-1,l[i],r[i]-1);if(roots[i]<0)return -1;}else ans[na++]=t.query(base,0,n-1,l[i],r[i]-1);}
 auto bytes=8*na;if(!out||cap<bytes)return -2;for(std::size_t i=0;i<na;i++)put(out,8*i,ans[i]);return (std::int64_t)bytes;
}
