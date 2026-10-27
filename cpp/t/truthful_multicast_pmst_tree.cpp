#include <cstddef>
#include <cstdint>

namespace {
constexpr int MaxN=8, MaxM=28, MaxInput=95, MaxOutput=176;
void put(std::uint8_t *o,std::size_t at,std::int64_t x){std::uint64_t b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;i++){o[at+i]=static_cast<std::uint8_t>(b&255);b>>=8;}}
int root(int *p,int x){while(p[x]!=x){p[x]=p[p[x]];x=p[x];}return x;}
}

extern "C" std::int64_t truthful_multicast_pmst_tree(const std::int64_t *a,std::size_t n,std::uint8_t *out,std::size_t cap){
    if(!a||n<4||n>MaxInput||a[0]<2||a[0]>MaxN||a[1]<a[0]-1||a[1]>MaxM||a[2]<0||a[2]>=a[0]||a[3]<1||a[3]>=a[0])return -1;
    int nv=int(a[0]),m=int(a[1]),source=int(a[2]),r=int(a[3]);if(n!=4+3*std::size_t(m)+std::size_t(r))return -1;
    int eu[MaxM],ev[MaxM],ew[MaxM],order[MaxM],pu=-1,pv=-1;
    for(int i=0;i<m;i++){auto u=a[4+3*i],v=a[5+3*i],w=a[6+3*i];if(u<0||v<=u||v>=nv||w<1||w>100||(i>0&&(u<pu||(u==pu&&v<=pv))))return -1;eu[i]=int(u);ev[i]=int(v);ew[i]=int(w);order[i]=i;pu=int(u);pv=int(v);}
    int receivers[MaxN],last=-1;for(int i=0;i<r;i++){auto x=a[4+3*m+i];if(x<0||x>=nv||x==source||(i>0&&x<=last))return -1;receivers[i]=int(x);last=int(x);}
    for(int i=1;i<m;i++){int key=order[i],j=i;while(j>0){int q=order[j-1];if(ew[q]<ew[key]||(ew[q]==ew[key]&&(eu[q]<eu[key]||(eu[q]==eu[key]&&ev[q]<ev[key]))))break;order[j]=q;--j;}order[j]=key;}
    int dsu[MaxN];for(int i=0;i<nv;i++)dsu[i]=i;int tu[MaxN-1],tv[MaxN-1],tw[MaxN-1],te=0;
    for(int z=0;z<m&&te<nv-1;z++){int e=order[z],x=root(dsu,eu[e]),y=root(dsu,ev[e]);if(x!=y){dsu[x]=y;tu[te]=eu[e];tv[te]=ev[e];tw[te]=ew[e];++te;}}
    if(te!=nv-1)return -1;
    int edgeAt[MaxN][MaxN];for(int i=0;i<nv;i++)for(int j=0;j<nv;j++)edgeAt[i][j]=-1;for(int e=0;e<te;e++){edgeAt[tu[e]][tv[e]]=e;edgeAt[tv[e]][tu[e]]=e;}
    int parent[MaxN],parentEdge[MaxN],stack[MaxN],top=0;for(int i=0;i<nv;i++){parent[i]=-1;parentEdge[i]=-1;}parent[source]=source;stack[top++]=source;
    while(top){int u=stack[--top];for(int v=0;v<nv;v++)if(edgeAt[u][v]>=0&&parent[v]<0){parent[v]=u;parentEdge[v]=edgeAt[u][v];stack[top++]=v;}}
    int keep[MaxN-1]={0};for(int i=0;i<r;i++){int v=receivers[i];while(v!=source){if(parent[v]<0)return -1;keep[parentEdge[v]]=1;v=parent[v];}}
    int selected[MaxN-1],count=0;for(int e=0;e<te;e++)if(keep[e])selected[count++]=e;
    for(int i=1;i<count;i++){int key=selected[i],j=i;while(j>0&&(tu[selected[j-1]]>tu[key]||(tu[selected[j-1]]==tu[key]&&tv[selected[j-1]]>tv[key]))){selected[j]=selected[j-1];--j;}selected[j]=key;}
    const std::size_t bytes=8*std::size_t(1+3*count);if(!out||cap<bytes)return -2;std::uint8_t staged[MaxOutput]{};put(staged,0,count);for(int i=0;i<count;i++){int e=selected[i];put(staged,8*std::size_t(1+3*i),tu[e]);put(staged,8*std::size_t(2+3*i),tv[e]);put(staged,8*std::size_t(3+3*i),tw[e]);}for(std::size_t i=0;i<bytes;i++)out[i]=staged[i];return std::int64_t(bytes);
}
