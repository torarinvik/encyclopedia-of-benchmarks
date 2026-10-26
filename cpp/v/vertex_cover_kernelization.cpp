// Clean-room high-/low-degree vertex-cover reduction profile.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N=16, M=64, INPUT=131, FIELDS=133;
void put(std::uint8_t* out,std::size_t at,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255u);bits>>=8;}}
}
extern "C" std::int64_t vertex_cover_kernelization(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
 if(!input||length<3||length>INPUT)return -1;auto nn=input[0],mm=input[1],kk=input[2];
 if(nn<1||nn>16||mm<0||mm>64||kk<0||kk>16||length!=3+2*static_cast<std::size_t>(mm))return -1;
 auto n=static_cast<std::size_t>(nn),m=static_cast<std::size_t>(mm);std::array<std::array<bool,N>,N> edge{};std::int64_t pu=-1,pv=-1;
 for(std::size_t e=0;e<m;++e){auto u=input[3+2*e],v=input[4+2*e];if(u<0||v<=u||v>=nn||u<pu||(u==pu&&v<=pv))return -1;edge[u][v]=edge[v][u]=true;pu=u;pv=v;}
 if(!output)return -2;std::array<bool,N> active{};for(std::size_t i=0;i<n;++i)active[i]=true;auto k=kk;std::uint64_t forced=0;bool infeasible=false;
 for(;;){if(k<0){infeasible=true;break;}std::size_t chosen=n,neighbor=n;int kind=0;
  for(std::size_t u=0;u<n;++u)if(active[u]){std::size_t d=0;for(std::size_t v=0;v<n;++v)d+=edge[u][v];if(d==0){chosen=u;kind=1;break;}}
  if(kind==1){active[chosen]=false;continue;}
  for(std::size_t u=0;u<n;++u)if(active[u]){std::size_t d=0,only=n;for(std::size_t v=0;v<n;++v)if(edge[u][v]){++d;only=v;}if(d==1){chosen=u;neighbor=only;kind=2;break;}}
  if(!kind)for(std::size_t u=0;u<n;++u)if(active[u]){std::size_t d=0;for(std::size_t v=0;v<n;++v)d+=edge[u][v];if(static_cast<std::int64_t>(d)>k){chosen=u;kind=3;break;}}
  if(!kind)break;auto f=kind==2?neighbor:chosen;forced|=std::uint64_t{1}<<f;active[f]=false;--k;for(std::size_t v=0;v<n;++v)edge[f][v]=edge[v][f]=false;
 }
 std::array<std::int64_t,FIELDS> out{};std::size_t count=0;out[count++]=infeasible?0:1;out[count++]=k;out[count++]=static_cast<std::int64_t>(forced);std::uint64_t active_mask=0;for(std::size_t v=0;v<n;++v)if(active[v])active_mask|=std::uint64_t{1}<<v;out[count++]=static_cast<std::int64_t>(active_mask);std::size_t rem=0;for(std::size_t u=0;u<n;++u)for(std::size_t v=u+1;v<n;++v)rem+=edge[u][v];out[count++]=static_cast<std::int64_t>(rem);for(std::size_t u=0;u<n;++u)for(std::size_t v=u+1;v<n;++v)if(edge[u][v]){out[count++]=static_cast<std::int64_t>(u);out[count++]=static_cast<std::int64_t>(v);}if(capacity<8*count)return -2;for(std::size_t i=0;i<count;++i)put(output,8*i,out[i]);return static_cast<std::int64_t>(8*count);
}
