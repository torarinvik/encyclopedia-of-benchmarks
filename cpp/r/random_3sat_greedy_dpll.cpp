#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr int V=12,C=32;constexpr std::size_t In=98,Out=104;void put(std::uint8_t*o,std::size_t at,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;i++){o[at+i]=static_cast<std::uint8_t>(b&255);b>>=8;}} }
extern "C" std::int64_t random_3sat_greedy_dpll(const std::int64_t*a,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!a||n<2||n>In||a[0]<3||a[0]>V||a[1]<0||a[1]>C)return -1;int nv=static_cast<int>(a[0]),m=static_cast<int>(a[1]);if(n!=static_cast<std::size_t>(2+3*m))return -1;
 std::array<std::array<int,3>,C>clauses{};std::array<int,C>len{};std::array<bool,C>active{};
 for(int i=0;i<m;i++){std::array<bool,V>seen{};for(int j=0;j<3;j++){auto x=a[2+3*i+j];if(x==0||x< -nv||x>nv)return -1;int v=static_cast<int>(x>0?x:-x)-1;if(seen[v])return -1;seen[v]=true;clauses[i][j]=static_cast<int>(x);}len[i]=3;active[i]=true;}
 std::array<int,V>assigned{};bool success=false,failed=false;
 for(int step=0;step<nv&&!failed;step++){int remaining=0;for(int i=0;i<m;i++)remaining+=active[i];if(remaining==0){success=true;break;}
  int chosen=0;for(int i=0;i<m&&chosen==0;i++)if(active[i]&&len[i]==1)chosen=clauses[i][0];
  if(chosen==0){std::array<int,2*V>counts{};for(int i=0;i<m;i++)if(active[i])for(int j=0;j<len[i];j++){int lit=clauses[i][j],v=(lit>0?lit:-lit)-1;counts[2*v+(lit<0)]++;}int best_count=0;for(int v=0;v<nv;v++)for(int sign=0;sign<2;sign++){int lit=sign?-(v+1):(v+1),value=counts[2*v+sign];if(value>best_count){chosen=lit;best_count=value;}}}
  if(chosen==0){failed=true;break;}int variable=(chosen>0?chosen:-chosen)-1;assigned[variable]=chosen>0?1:-1;
  for(int i=0;i<m;i++)if(active[i]){bool satisfied=false;for(int j=0;j<len[i];j++)if(clauses[i][j]==chosen)satisfied=true;if(satisfied){active[i]=false;continue;}int w=0;for(int j=0;j<len[i];j++)if(clauses[i][j]!=-chosen)clauses[i][w++]=clauses[i][j];len[i]=w;if(w==0){failed=true;break;}}
 }
 if(!failed){int remaining=0;for(int i=0;i<m;i++)remaining+=active[i];success=remaining==0;}
 if(success)for(int i=0;i<nv;i++)if(assigned[i]==0)assigned[i]=-1;const std::size_t bytes=8*static_cast<std::size_t>(nv+1);if(!out||cap<bytes)return -2;std::array<std::uint8_t,Out>staged{};put(staged.data(),0,success?1:0);for(int i=0;i<nv;i++)put(staged.data(),8*static_cast<std::size_t>(i+1),assigned[i]);for(std::size_t i=0;i<bytes;i++)out[i]=staged[i];return static_cast<std::int64_t>(bytes);
}
