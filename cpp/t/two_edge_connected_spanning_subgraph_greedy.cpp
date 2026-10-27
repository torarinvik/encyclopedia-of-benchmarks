#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t N=8,M=28,INPUT=59;
void put(std::uint8_t*o,std::size_t at,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;++i){o[at+i]=static_cast<std::uint8_t>(b&255U);b>>=8;}}
bool connected(std::size_t n,std::size_t m,const std::size_t*u,const std::size_t*v,const bool*on,int skip){bool seen[N]{};std::size_t q[N]{},h=0,t=1;q[0]=0;seen[0]=true;while(h<t){auto a=q[h++];for(std::size_t e=0;e<m;++e)if(on[e]&&static_cast<int>(e)!=skip){std::size_t b=N;if(u[e]==a)b=v[e];else if(v[e]==a)b=u[e];if(b<N&&!seen[b]){seen[b]=true;q[t++]=b;}}}for(std::size_t i=0;i<n;++i)if(!seen[i])return false;return true;}
bool edgeConnected(std::size_t n,std::size_t m,const std::size_t*u,const std::size_t*v,const bool*on){if(!connected(n,m,u,v,on,-1))return false;for(std::size_t e=0;e<m;++e)if(on[e]&&!connected(n,m,u,v,on,static_cast<int>(e)))return false;return true;}
}
extern "C" std::int64_t two_edge_connected_spanning_subgraph_greedy(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{
 if(!in||len<2||len>INPUT)return -1;auto n0=in[0],m0=in[1];if(n0<3||n0>8||m0<3||m0>28||len!=2+2*static_cast<std::size_t>(m0))return -1;auto n=static_cast<std::size_t>(n0),m=static_cast<std::size_t>(m0);std::size_t u[M]{},v[M]{};bool on[M]{};
 for(std::size_t i=0;i<m;++i){auto a=in[2+2*i],b=in[3+2*i];if(a<0||a>=b||b>=n0)return -1;u[i]=static_cast<std::size_t>(a);v[i]=static_cast<std::size_t>(b);on[i]=true;for(std::size_t j=0;j<i;++j)if(u[i]==u[j]&&v[i]==v[j])return -1;}
 if(!edgeConnected(n,m,u,v,on))return -1;for(std::size_t e=0;e<m;++e){on[e]=false;if(!edgeConnected(n,m,u,v,on))on[e]=true;}
 std::size_t count=0;for(std::size_t e=0;e<m;++e)if(on[e])++count;auto bytes=8*(1+2*count);if(!out||cap<bytes)return -2;put(out,0,static_cast<std::int64_t>(count));std::size_t at=8;for(std::size_t a=0;a<n;++a)for(std::size_t b=a+1;b<n;++b)for(std::size_t e=0;e<m;++e)if(on[e]&&u[e]==a&&v[e]==b){put(out,at,static_cast<std::int64_t>(a));put(out,at+8,static_cast<std::int64_t>(b));at+=16;}return static_cast<std::int64_t>(bytes);
}
