#include <array>
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr int N=8,M=16,K=8; constexpr std::size_t In=75,Out=648; void put(std::uint8_t*o,std::size_t at,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;i++){o[at+i]=static_cast<std::uint8_t>(b&255);b>>=8;}} }
extern "C" std::int64_t truthful_ufp_greedy1(const std::int64_t*a,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!a||n<9||n>In||a[0]<2||a[0]>N||a[1]<1||a[1]>M||a[2]<1||a[2]>K)return -1;int nv=a[0],m=a[1],k=a[2];if(n!=static_cast<std::size_t>(3+3*m+3*k))return -1;
 std::array<int,M>eu{},ev{},bc{};std::array<double,M>y{};int B=9,pu=-1,pv=-1;for(int e=0;e<m;e++){auto u=a[3+3*e],v=a[4+3*e],b=a[5+3*e];if(u<0||v<=u||v>=nv||b<2||b>8||(e>0&&(u<pu||(u==pu&&v<=pv))))return -1;eu[e]=u;ev[e]=v;bc[e]=b;y[e]=1.0/static_cast<double>(b);B=std::min(B,static_cast<int>(b));pu=u;pv=v;}
 std::array<int,K>src{},dst{},value{};for(int i=0;i<k;i++){auto s=a[3+3*m+3*i],t=a[4+3*m+3*i],c=a[5+3*m+3*i];if(s<0||s>=nv||t<0||t>=nv||s==t||c<1||c>100)return -1;src[i]=s;dst[i]=t;value[i]=c;}
 const double threshold=std::pow(2.718281828459045,static_cast<double>(B-1))*m;std::array<bool,K>live{};for(int i=0;i<k;i++)live[i]=true;std::array<int,K>chosen{},plen{};std::array<int,K*N>paths{};int count=0;
 while(count<k){int best=-1;double bestScore=-1.0;std::array<int,K*N>routeTable{};std::array<int,K>routeLen{};
  for(int i=0;i<k;i++)if(live[i]){std::array<double,N>d;std::array<int,N>prev{};std::array<bool,N>used{};for(int v=0;v<nv;v++){d[v]=1e300;prev[v]=-1;}d[src[i]]=0;
   for(int step=0;step<nv;step++){int u=-1;for(int v=0;v<nv;v++)if(!used[v]&&(u<0||d[v]<d[u]||(d[v]==d[u]&&v<u)))u=v;if(u<0||d[u]>=1e299)break;used[u]=true;for(int e=0;e<m;e++){int v=eu[e]==u?ev[e]:(ev[e]==u?eu[e]:-1);if(v<0||used[v])continue;double cand=d[u]+y[e];if(cand<d[v]||(cand==d[v]&&(prev[v]<0||u<prev[v]))){d[v]=cand;prev[v]=u;}}}
   if(d[dst[i]]>=1e299)return -1;std::array<int,N>rev{};int len=0,v=dst[i];while(v!=src[i]&&len<nv){rev[len++]=v;v=prev[v];if(v<0)return -1;}if(v!=src[i])return -1;rev[len++]=src[i];routeLen[i]=len;for(int q=0;q<len;q++)routeTable[i*N+q]=rev[len-1-q];double score=static_cast<double>(value[i])/d[dst[i]];if(best<0||score>bestScore){best=i;bestScore=score;}}
  if(best<0)break;live[best]=false;chosen[count]=best;plen[count]=routeLen[best];for(int q=0;q<plen[count];q++)paths[count*N+q]=routeTable[best*N+q];++count;
  for(int q=0;q<plen[count-1]-1;q++){int u=paths[(count-1)*N+q],v=paths[(count-1)*N+q+1];for(int e=0;e<m;e++)if((eu[e]==u&&ev[e]==v)||(eu[e]==v&&ev[e]==u))y[e]*=std::pow(threshold,1.0/static_cast<double>(bc[e]-1));}
  double dual=0;for(int e=0;e<m;e++)dual+=bc[e]*y[e];if(dual>=threshold)break;
 }
 std::size_t words=1;for(int i=0;i<count;i++)words+=2+plen[i];auto bytes=8*words;if(!out||cap<bytes)return -2;std::array<std::uint8_t,Out>staged{};put(staged.data(),0,count);std::size_t w=1;for(int i=0;i<count;i++){put(staged.data(),8*w++,chosen[i]);put(staged.data(),8*w++,plen[i]);for(int q=0;q<plen[i];q++)put(staged.data(),8*w++,paths[i*N+q]);}for(std::size_t i=0;i<bytes;i++)out[i]=staged[i];return static_cast<std::int64_t>(bytes);
}
