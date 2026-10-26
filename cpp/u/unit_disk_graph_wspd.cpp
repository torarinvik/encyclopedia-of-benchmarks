#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int N = 8, PAIRS = 28, INPUT = 18, OUTPUT = 456;
struct Context { int n{}, c{}, count{}; std::int64_t d[N][N]{}; std::uint64_t left[PAIRS]{}, right[PAIRS]{}; };
int size(std::uint64_t m) { int n=0; for(;m;m>>=1) n+=int(m&1); return n; }
void split(std::uint64_t m,std::uint64_t &a,std::uint64_t &b) { a=b=0; int half=size(m)/2,k=0; for(int i=0;i<N;++i)if(m&(std::uint64_t(1)<<i)){if(k++<half)a|=std::uint64_t(1)<<i;else b|=std::uint64_t(1)<<i;} }
std::int64_t diam(const Context&x,std::uint64_t m){std::int64_t z=0;for(int i=0;i<x.n;++i)if(m&(std::uint64_t(1)<<i))for(int j=i+1;j<x.n;++j)if((m&(std::uint64_t(1)<<j))&&x.d[i][j]>z)z=x.d[i][j];return z;}
std::int64_t between(const Context&x,std::uint64_t a,std::uint64_t b){auto z=std::numeric_limits<std::int64_t>::max();for(int i=0;i<x.n;++i)if(a&(std::uint64_t(1)<<i))for(int j=0;j<x.n;++j)if((b&(std::uint64_t(1)<<j))&&x.d[i][j]<z)z=x.d[i][j];return z;}
void cross(Context&x,std::uint64_t a,std::uint64_t b){if(between(x,a,b)>=x.c*(diam(x,a)>diam(x,b)?diam(x,a):diam(x,b))){if(x.count<PAIRS){x.left[x.count]=a;x.right[x.count]=b;++x.count;}return;}if(size(a)>=size(b)&&size(a)>1){std::uint64_t l,r;split(a,l,r);cross(x,l,b);cross(x,r,b);}else{std::uint64_t l,r;split(b,l,r);cross(x,a,l);cross(x,a,r);}}
void visit(Context&x,std::uint64_t m){if(size(m)<2)return;std::uint64_t l,r;split(m,l,r);visit(x,l);visit(x,r);cross(x,l,r);}
void put(std::uint8_t*out,std::size_t at,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(int i=0;i<8;++i){out[at+i]=static_cast<std::uint8_t>(b);b>>=8;}}
}
extern "C" std::int64_t unit_disk_graph_wspd(const std::int64_t*v,std::size_t length,std::uint8_t*out,std::size_t cap){
 if(!v||length<4||length>INPUT||v[0]<1||v[0]>N||v[1]<1||v[1]>8||length!=2+2*static_cast<std::size_t>(v[0]))return -1;
 Context x{};x.n=static_cast<int>(v[0]);x.c=static_cast<int>(v[1]);std::int64_t px[N]{},py[N]{};
 for(int i=0;i<x.n;++i){px[i]=v[2+2*i];py[i]=v[3+2*i];if(px[i]<-8||px[i]>8||py[i]<-8||py[i]>8)return -1;for(int j=0;j<i;++j)if(px[i]==px[j]&&py[i]==py[j])return -1;}
 constexpr std::int64_t INF=std::numeric_limits<std::int64_t>::max()/4;
 for(int i=0;i<x.n;++i)for(int j=0;j<x.n;++j)x.d[i][j]=i==j?0:INF;
 for(int i=0;i<x.n;++i)for(int j=i+1;j<x.n;++j){auto dx=px[i]-px[j],dy=py[i]-py[j];if(dx*dx+dy*dy<=1)x.d[i][j]=x.d[j][i]=1;}
 for(int k=0;k<x.n;++k)for(int i=0;i<x.n;++i)for(int j=0;j<x.n;++j)if(x.d[i][k]+x.d[k][j]<x.d[i][j])x.d[i][j]=x.d[i][k]+x.d[k][j];
 for(int i=0;i<x.n;++i)for(int j=0;j<x.n;++j)if(x.d[i][j]>=INF/2)return -1;
 visit(x,(std::uint64_t(1)<<x.n)-1);std::size_t bytes=8+16*static_cast<std::size_t>(x.count);std::uint8_t stage[OUTPUT]{};put(stage,0,x.count);for(int i=0;i<x.count;++i){put(stage,8+16*i,static_cast<std::int64_t>(x.left[i]));put(stage,16+16*i,static_cast<std::int64_t>(x.right[i]));}if(!out||cap<bytes)return -2;for(std::size_t i=0;i<bytes;++i)out[i]=stage[i];return static_cast<std::int64_t>(bytes);
}
