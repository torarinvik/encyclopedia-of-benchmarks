#include <stddef.h>
#include <stdint.h>
#define N 64
#define MAX_ARCS (N*(N-1))
typedef struct { int to[N-1]; int degree; } Adj;
static void put(uint8_t*out,size_t slot,int64_t v){uint64_t b=(uint64_t)v;for(size_t i=0;i<8;i++)out[slot*8+i]=(uint8_t)(b>>(8*i));}
int64_t bidirectional_search(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<4||in[0]<1||in[0]>N)return -1;int n=(int)in[0];if(in[1]<0||in[1]>=n||in[2]<0||in[2]>=n||in[3]<0||in[3]>MAX_ARCS||len!=4+2*(size_t)in[3])return -1;
 Adj adj[N]={0};uint8_t edge[N][N]={{0}};size_t m=(size_t)in[3];for(size_t i=0;i<m;i++){int64_t u=in[4+2*i],v=in[5+2*i];if(u<0||u>=n||v<0||v>=n||u==v||edge[u][v])return -1;edge[u][v]=1;adj[u].to[adj[u].degree++]=(int)v;}for(int u=0;u<n;u++)for(int v=0;v<n;v++)if(edge[u][v]!=edge[v][u])return -1;
 int64_t path[N];size_t pc=0;int start=(int)in[1],goal=(int)in[2];if(start==goal)path[pc++]=start;else{
  int parent[2][N];for(int s=0;s<2;s++)for(int i=0;i<n;i++)parent[s][i]=-2;int q[2][N],head[2]={0,0},tail[2]={0,0};parent[0][start]=-1;parent[1][goal]=-1;q[0][tail[0]++]=start;q[1][tail[1]++]=goal;int meet=-1;
  while(head[0]<tail[0]&&head[1]<tail[1]&&meet<0){for(int side=0;side<2&&meet<0;side++){int cur=q[side][head[side]++];for(int j=0;j<adj[cur].degree;j++){int v=adj[cur].to[j];if(parent[side][v]!=-2)continue;parent[side][v]=cur;q[side][tail[side]++]=v;if(parent[1-side][v]!=-2){meet=v;break;}}}}
  if(meet>=0){int rev[N],k=0;for(int v=meet;v!=-1;v=parent[0][v])rev[k++]=v;for(int i=k-1;i>=0;i--)path[pc++]=rev[i];for(int v=parent[1][meet];v!=-1;v=parent[1][v])path[pc++]=v;}
 }
 size_t bytes=(1+pc)*8;if(!out||cap<bytes)return -2;put(out,0,(int64_t)pc);for(size_t i=0;i<pc;i++)put(out,1+i,path[i]);return (int64_t)bytes;
}
