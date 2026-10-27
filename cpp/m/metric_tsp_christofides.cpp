#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <vector>

namespace { constexpr int N=8, M=256; std::int64_t d[N][N], memo[M]; int choice[M], oddv[N], oddn;
void put64(std::uint8_t* o,std::size_t p,std::int64_t x){auto u=static_cast<std::uint64_t>(x);for(int b=0;b<8;b++){o[p+b]=static_cast<std::uint8_t>(u&255);u>>=8;}}
std::int64_t match(int mask){if(!mask)return 0;if(memo[mask]>=0)return memo[mask];int i=0;while(!(mask&(1<<i)))++i;int rest=mask^(1<<i),bj=-1;auto best=std::numeric_limits<std::int64_t>::max();for(int j=i+1;j<oddn;j++)if(rest&(1<<j)){auto v=d[oddv[i]][oddv[j]]+match(rest^(1<<j));if(v<best){best=v;bj=j;}}choice[mask]=bj;return memo[mask]=best;}
}
extern "C" std::int64_t metric_tsp_christofides(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap) noexcept {
 if(!in||len<2||len>65)return -1;auto n0=in[0];if(n0<1||n0>N||len!=1+static_cast<std::size_t>(n0*n0))return -1;int n=static_cast<int>(n0);
 for(int i=0;i<n;i++)for(int j=0;j<n;j++){auto w=in[1+i*n+j];if(w<0||w>10000||(i==j&&w))return -1;d[i][j]=w;}
 for(int i=0;i<n;i++)for(int j=0;j<n;j++){if(d[i][j]!=d[j][i])return -1;for(int k=0;k<n;k++)if(d[i][j]>d[i][k]+d[k][j])return -1;}
 auto bytes=static_cast<std::size_t>(8*(n+2));if(!out||cap<bytes)return -2;
 bool used[N][N]{},tree[N][N]{};int parent[N];for(int i=0;i<n;i++)parent[i]=i;
 auto root=[&](int x){while(parent[x]!=x)x=parent[x];return x;};int accepted=0;
 for(int step=0;step<n*(n-1)/2&&accepted<n-1;step++){int bu=-1,bv=-1;auto bw=std::numeric_limits<std::int64_t>::max();for(int u=0;u<n;u++)for(int v=u+1;v<n;v++)if(!used[u][v]&&(d[u][v]<bw||(d[u][v]==bw&&(bu<0||u<bu||(u==bu&&v<bv))))){bu=u;bv=v;bw=d[u][v];}used[bu][bv]=true;int a=root(bu),b=root(bv);if(a!=b){parent[b]=a;tree[bu][bv]=tree[bv][bu]=true;++accepted;}}
 int deg[N]{};oddn=0;for(int i=0;i<n;i++){for(int j=0;j<n;j++)deg[i]+=tree[i][j];if(deg[i]&1)oddv[oddn++]=i;}
 for(int i=0;i<M;i++){memo[i]=-1;choice[i]=-1;}memo[0]=0;int mask=(1<<oddn)-1;match(mask);
 int multi[N][N]{};for(int i=0;i<n;i++)for(int j=i+1;j<n;j++)if(tree[i][j])multi[i][j]=multi[j][i]=1;
 while(mask){int i=0;while(!(mask&(1<<i)))++i;int j=choice[mask],u=oddv[i],v=oddv[j];++multi[u][v];++multi[v][u];mask^=(1<<i)|(1<<j);}
 std::vector<int> st{0},rev;while(!st.empty()){int v=st.back(),w=-1;for(int x=0;x<n;x++)if(multi[v][x]){w=x;break;}if(w<0){rev.push_back(v);st.pop_back();}else{--multi[v][w];--multi[w][v];st.push_back(w);}}
 std::array<bool,N> seen{};std::vector<int> order;for(auto it=rev.rbegin();it!=rev.rend();++it)if(!seen[*it]){seen[*it]=true;order.push_back(*it);}
 std::int64_t cost=0;for(int i=0;i<n-1;i++)cost+=d[order[i]][order[i+1]];cost+=d[order[n-1]][0];put64(out,0,cost);for(int i=0;i<n;i++)put64(out,8*(i+1),order[i]);put64(out,8*(n+1),0);return static_cast<std::int64_t>(bytes);
}
