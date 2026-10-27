#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N=8,MAX_M=16,MAX_WORLDS=8;
void put_i64(std::uint8_t*out,std::size_t word,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[word*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}
int infected_count(int n,int m,int world,std::uint16_t sources,std::uint16_t protectors,
 const int eu[MAX_M],const int ev[MAX_M],const int masks[MAX_M]){
 int status[MAX_N]{},rf[MAX_N]{},pf[MAX_N]{};
 for(int v=0;v<n;++v){if(sources&(1u<<v)){status[v]=1;rf[v]=1;}if(protectors&(1u<<v)){status[v]=2;pf[v]=1;}}
 for(int step=0;step<n;++step){int rp[MAX_N]{},pp[MAX_N]{};
  for(int e=0;e<m;++e){int u=eu[e],v=ev[e];if(status[v])continue;if(pf[u])pp[v]=1;if(rf[u]&&(masks[e]&(1<<world)))rp[v]=1;}
  int nr[MAX_N]{},np[MAX_N]{},changed=0;
  for(int v=0;v<n;++v)if(!status[v]){if(pp[v]){status[v]=2;np[v]=1;changed=1;}else if(rp[v]){status[v]=1;nr[v]=1;changed=1;}}
  for(int v=0;v<n;++v){rf[v]=nr[v];pf[v]=np[v];}if(!changed)break;
 }
 int count=0;for(int v=0;v<n;++v)if(status[v]==1)++count;return count;
}
}
extern "C" std::int64_t rumor_blocking_greedy_live_edge(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 if(input==nullptr||length<5||length>61)return -1;
 auto n0=input[0],m0=input[1],r0=input[2],k0=input[3],w0=input[4];
 if(n0<2||n0>8||m0<0||m0>16||r0<1||r0>=n0||k0<1||k0>3||w0<1||w0>8||k0>n0-r0||length!=5+static_cast<std::size_t>(r0)+3*static_cast<std::size_t>(m0))return -1;
 int n=static_cast<int>(n0),m=static_cast<int>(m0),r=static_cast<int>(r0),k=static_cast<int>(k0),worlds=static_cast<int>(w0);std::uint16_t sources=0;
 for(int i=0;i<r;++i){auto v=input[5+i];if(v<0||v>=n||(sources&(1u<<v)))return -1;sources|=static_cast<std::uint16_t>(1u<<v);}
 int eu[MAX_M]{},ev[MAX_M]{},masks[MAX_M]{};const auto at=5+r;const int allowed=(1<<worlds)-1;
 for(int e=0;e<m;++e){auto u=input[at+3*e],v=input[at+3*e+1],mask=input[at+3*e+2];if(u<0||u>=n||v<0||v>=n||u==v||mask<0||mask>allowed)return -1;for(int j=0;j<e;++j)if(eu[j]==u&&ev[j]==v)return -1;eu[e]=static_cast<int>(u);ev[e]=static_cast<int>(v);masks[e]=static_cast<int>(mask);}
 int baseline[MAX_WORLDS]{};for(int w=0;w<worlds;++w)baseline[w]=infected_count(n,m,w,sources,0,eu,ev,masks);
 std::uint16_t selected=0;int chosen[MAX_N]{},scores[MAX_N]{};
 for(int round=0;round<k;++round){int current[MAX_WORLDS]{};for(int w=0;w<worlds;++w)current[w]=baseline[w]-infected_count(n,m,w,sources,selected,eu,ev,masks);int best=-1,best_score=-1;
  for(int candidate=0;candidate<n;++candidate){if((sources&(1u<<candidate))||(selected&(1u<<candidate)))continue;int score=0;for(int w=0;w<worlds;++w)score+=baseline[w]-infected_count(n,m,w,sources,static_cast<std::uint16_t>(selected|(1u<<candidate)),eu,ev,masks)-current[w];if(score>best_score){best=candidate;best_score=score;}}
  if(best<0)return -1;selected|=static_cast<std::uint16_t>(1u<<best);chosen[round]=best;scores[round]=best_score;
 }
 const auto bytes=static_cast<std::size_t>(1+2*k)*8;if(output==nullptr||capacity<bytes)return -2;put_i64(output,0,k);for(int i=0;i<k;++i){put_i64(output,1+2*i,chosen[i]);put_i64(output,2+2*i,scores[i]);}return static_cast<std::int64_t>(bytes);
}
