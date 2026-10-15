#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int max_n=16, max_m=64;
int root(int parent[max_n],int x){while(parent[x]!=x){parent[x]=parent[parent[x]];x=parent[x];}return x;}
}
extern "C" std::int64_t boruvkas_minimum_spanning_tree(const std::int64_t* input,std::size_t length) noexcept {
    if(!input||length<2)return -1;auto nv=input[0],mv=input[1];
    if(nv<2||nv>max_n||mv<nv-1||mv>max_m||mv>nv*(nv-1)/2)return -1;
    int n=static_cast<int>(nv),m=static_cast<int>(mv);if(length!=static_cast<std::size_t>(2+3*m))return -1;
    constexpr auto inf=std::numeric_limits<std::int64_t>::max();std::int64_t w[max_n][max_n];
    for(int i=0;i<n;i++)for(int j=0;j<n;j++)w[i][j]=inf;
    for(int k=0;k<m;k++){auto u=input[2+3*k],v=input[3+3*k],x=input[4+3*k];if(u<1||u>nv||v<1||v>nv||u==v||x<1||x>100||w[u-1][v-1]!=inf)return -1;w[u-1][v-1]=w[v-1][u-1]=x;}
    int p[max_n],components=n;for(int i=0;i<n;i++)p[i]=i;std::int64_t total=0;
    while(components>1){int bu[max_n],bv[max_n];std::int64_t bw[max_n];for(int i=0;i<n;i++){bu[i]=bv[i]=-1;bw[i]=inf;}
        for(int u=0;u<n;u++)for(int v=u+1;v<n;v++)if(w[u][v]!=inf){int a=root(p,u),b=root(p,v);if(a!=b){if(w[u][v]<bw[a]){bw[a]=w[u][v];bu[a]=u;bv[a]=v;}if(w[u][v]<bw[b]){bw[b]=w[u][v];bu[b]=u;bv[b]=v;}}}
        int merged=0;for(int r=0;r<n;r++)if(bu[r]>=0){int a=root(p,bu[r]),b=root(p,bv[r]);if(a!=b){p[a]=b;--components;total+=bw[r];merged=1;}}if(!merged)return -1;
    }return total;
}
