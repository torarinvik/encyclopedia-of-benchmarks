// Clean-room exact branch-and-search vertex-cover profile.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t N=16,INPUT=131;
unsigned count_bits(std::uint64_t x){unsigned n=0;while(x){n+=static_cast<unsigned>(x&1u);x>>=1;}return n;}
using Graph=std::array<std::array<bool,N>,N>;
std::uint64_t search(const Graph&g,std::size_t n,std::uint64_t active){
 std::size_t chosen=n;unsigned best=0;bool any=false;
 for(std::size_t u=0;u<n;++u)if(active>>u&1u){unsigned d=0;for(std::size_t v=0;v<n;++v)if(active>>v&1u)d+=g[u][v];if(d){any=true;if(chosen==n||d>best){chosen=u;best=d;}}}
 if(!any)return 0;const auto bit=std::uint64_t{1}<<chosen;auto first=bit|search(g,n,active&~bit);std::uint64_t neighbors=0;for(std::size_t v=0;v<n;++v)if((active>>v&1u)&&g[chosen][v])neighbors|=std::uint64_t{1}<<v;auto second=neighbors|search(g,n,active&~(neighbors|bit));auto a=count_bits(first),b=count_bits(second);return a<b?first:b<a?second:std::min(first,second);
}
void put(std::uint8_t*out,std::size_t at,std::int64_t x){auto bits=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255u);bits>>=8;}}
}
extern "C" std::int64_t vertex_cover_search_trees(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 if(!input||length<3||length>INPUT)return -1;auto nn=input[0],mm=input[1],k=input[2];if(nn<1||nn>16||mm<0||mm>64||k<0||k>nn||length!=3+2*static_cast<std::size_t>(mm))return -1;
 Graph g{};std::int64_t pu=-1,pv=-1;for(std::size_t e=0;e<static_cast<std::size_t>(mm);++e){auto u=input[3+2*e],v=input[4+2*e];if(u<0||v<=u||v>=nn||u<pu||(u==pu&&v<=pv))return -1;g[u][v]=g[v][u]=true;pu=u;pv=v;}
 if(!output||capacity<24)return -2;auto all=(std::uint64_t{1}<<static_cast<std::size_t>(nn))-1;auto cover=search(g,static_cast<std::size_t>(nn),all);auto count=static_cast<std::int64_t>(count_bits(cover));put(output,0,count<=k?1:0);put(output,8,count);put(output,16,static_cast<std::int64_t>(cover));return 24;
}
