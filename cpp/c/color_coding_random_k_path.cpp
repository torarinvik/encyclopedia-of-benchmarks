#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N=12,M=66,K=6,T=8;
constexpr std::size_t IN=232,OUT=64;
void put(std::uint8_t*out,std::size_t at,std::int64_t x){auto bits=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255u);bits>>=8;}}
bool path_less(const std::array<std::int8_t,K>&a,const std::array<std::int8_t,K>&b,int len){for(int i=0;i<len;++i){if(a[i]!=b[i])return a[i]<b[i];}return false;}
}

extern "C" std::int64_t color_coding_random_k_path(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 if(!input||length<4||length>IN||input[0]<1||input[0]>N||input[1]<0||input[1]>M||input[2]<1||input[2]>K||input[2]>input[0]||input[3]<1||input[3]>T)return -1;
 int n=static_cast<int>(input[0]),m=static_cast<int>(input[1]),k=static_cast<int>(input[2]),trials=static_cast<int>(input[3]);std::size_t edge_start=4,color_start=edge_start+2*static_cast<std::size_t>(m);if(length!=color_start+static_cast<std::size_t>(trials*n))return -1;
 std::array<std::uint16_t,N>adj{};
 for(int e=0;e<m;++e){auto av=input[edge_start+2*static_cast<std::size_t>(e)],bv=input[edge_start+2*static_cast<std::size_t>(e)+1];if(av<0||bv<0||av>=n||bv>=n||av==bv)return -1;int a=static_cast<int>(av),b=static_cast<int>(bv);if(adj[a]&(1u<<b))return -1;adj[a]|=static_cast<std::uint16_t>(1u<<b);adj[b]|=static_cast<std::uint16_t>(1u<<a);}
 for(int t=0;t<trials;++t)for(int v=0;v<n;++v){auto c=input[color_start+static_cast<std::size_t>(t*n+v)];if(c<0||c>=k)return -1;}
 int full=(1<<k)-1;
 for(int trial=0;trial<trials;++trial){std::array<int,N>colors{};for(int v=0;v<n;++v)colors[v]=static_cast<int>(input[color_start+static_cast<std::size_t>(trial*n+v)]);
  std::array<std::array<bool,N>,1<<K>reach{};std::array<std::array<std::array<std::int8_t,K>,N>,1<<K>paths{};for(int mask=0;mask<=full;++mask)for(int v=0;v<n;++v)paths[mask][v].fill(-1);
  for(int v=0;v<n;++v){int mask=1<<colors[v];reach[mask][v]=true;paths[mask][v][0]=static_cast<std::int8_t>(v);}
  for(int mask=1;mask<=full;++mask){int plen=0;for(int x=mask;x;x&=x-1)++plen;for(int v=0;v<n;++v)if(reach[mask][v]&&mask!=full)for(int u=0;u<n;++u){int cb=1<<colors[u];if(!(adj[v]&(1u<<u))||(mask&cb))continue;int next=mask|cb;auto candidate=paths[mask][v];candidate[plen]=static_cast<std::int8_t>(u);if(!reach[next][u]||path_less(candidate,paths[next][u],plen+1)){reach[next][u]=true;paths[next][u]=candidate;}}}
  int best=-1;for(int v=0;v<n;++v)if(reach[full][v]&&(best<0||path_less(paths[full][v],paths[full][best],k)))best=v;
  if(best>=0){std::size_t bytes=8*static_cast<std::size_t>(k+2);if(!output||capacity<bytes)return -2;std::array<std::uint8_t,OUT>staged{};put(staged.data(),0,1);put(staged.data(),8,trial+1);for(int j=0;j<k;++j)put(staged.data(),8*static_cast<std::size_t>(j+2),paths[full][best][j]);for(std::size_t i=0;i<bytes;++i)output[i]=staged[i];return static_cast<std::int64_t>(bytes);}
 }
 if(!output||capacity<16)return -2;std::array<std::uint8_t,16>staged{};put(staged.data(),0,0);put(staged.data(),8,0);for(int i=0;i<16;++i)output[i]=staged[i];return 16;
}
