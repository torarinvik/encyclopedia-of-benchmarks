// Clean-room bounded iterative-compression feedback vertex set profile.
#include <array>
#include <cstddef>
#include <cstdint>
namespace {constexpr std::size_t N=8,INPUT=59;using Graph=std::array<std::array<bool,N>,N>;
unsigned bits(std::uint64_t x){unsigned n=0;while(x){n+=static_cast<unsigned>(x&1u);x>>=1;}return n;}
std::size_t root(std::array<std::size_t,N>&p,std::size_t x){while(p[x]!=x){p[x]=p[p[x]];x=p[x];}return x;}
bool forest(const Graph&g,std::size_t n,std::uint64_t vertices){std::array<std::size_t,N> p{};for(std::size_t i=0;i<n;++i)p[i]=i;for(std::size_t u=0;u<n;++u)if(vertices>>u&1u)for(std::size_t v=u+1;v<n;++v)if((vertices>>v&1u)&&g[u][v]){auto a=root(p,u),b=root(p,v);if(a==b)return false;p[a]=b;}return true;}
bool compress(const Graph&g,std::size_t n,std::uint64_t prefix,unsigned k,std::uint64_t current,std::uint64_t&result){for(auto x=current;;x=(x-1)&current){auto cx=bits(x);auto excluded=current&~x;if(cx<=k&&forest(g,n,excluded)){auto eligible=prefix&~current;for(auto s=eligible;;s=(s-1)&eligible){if(bits(s)<=k-cx&&forest(g,n,prefix&~(x|s))){result=x|s;return true;}if(s==0)break;}}if(x==0)break;}return false;}
bool solve_budget(const Graph&g,std::size_t n,unsigned k,std::uint64_t&answer){std::uint64_t fvs=0;for(std::size_t i=0;i<n;++i){const auto prefix=(std::uint64_t{1}<<(i+1))-1;const auto candidate=fvs|(std::uint64_t{1}<<i);if(bits(candidate)<=k){fvs=candidate;continue;}std::uint64_t next=0;if(!compress(g,n,prefix,k,candidate,next))return false;fvs=next;}answer=fvs;return true;}
void put(std::uint8_t*out,std::size_t at,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;++i){out[at+i]=static_cast<std::uint8_t>(b&255u);b>>=8;}}
}
extern "C" std::int64_t undirected_feedback_vertex_set(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){if(!input||length<3||length>INPUT)return -1;auto nn=input[0],mm=input[1],limit=input[2];if(nn<1||nn>8||mm<0||mm>28||limit<0||limit>4||length!=3+2*static_cast<std::size_t>(mm))return -1;const auto n=static_cast<std::size_t>(nn);Graph g{};std::int64_t pu=-1,pv=-1;for(std::size_t e=0;e<static_cast<std::size_t>(mm);++e){auto u=input[3+2*e],v=input[4+2*e];if(u<0||v<=u||v>=nn||u<pu||(u==pu&&v<=pv))return -1;g[u][v]=g[v][u]=true;pu=u;pv=v;}if(!output||capacity<16)return -2;bool found=false;unsigned minimum=0;std::uint64_t answer=0;for(unsigned k=0;k<=static_cast<unsigned>(limit);++k)if(solve_budget(g,n,k,answer)){found=true;minimum=k;break;}put(output,0,found?1:0);put(output,8,found?static_cast<std::int64_t>(minimum):-1);return 16;}
