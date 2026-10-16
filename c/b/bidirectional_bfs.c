#include <stddef.h>
#include <stdint.h>
#define MAX_VERTICES 64
#define MAX_ARCS 4096
static void put(uint8_t*out,size_t slot,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;b++)out[slot*8+b]=(uint8_t)(bits>>(8*b));}
int64_t bidirectional_bfs(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(!input||length<4)return -1;int64_t nv=input[0],av=input[1],sv=input[2],tv=input[3];if(nv<1||nv>MAX_VERTICES||av<0||av>MAX_ARCS||sv<0||sv>=nv||tv<0||tv>=nv||length!=4+2*(size_t)av)return -1;size_t n=(size_t)nv,m=(size_t)av;
 uint8_t edge[MAX_VERTICES][MAX_VERTICES]={{0}};int adj[MAX_VERTICES][MAX_VERTICES],deg[MAX_VERTICES]={0};for(size_t i=0;i<m;i++){int64_t u=input[4+2*i],v=input[5+2*i];if(u<0||u>=nv||v<0||v>=nv)return -1;if(!edge[u][v]){edge[u][v]=1;adj[u][deg[u]++]=(int)v;}}for(size_t u=0;u<n;u++)for(size_t v=0;v<n;v++)if(edge[u][v]!=edge[v][u])return -1;
 int start=(int)sv,target=(int)tv,path[MAX_VERTICES];size_t pc=0;if(start==target)path[pc++]=start;else{uint8_t seen[2][MAX_VERTICES]={{0}};int parent[2][MAX_VERTICES];int q[2][MAX_VERTICES],head[2]={0,0},tail[2]={0,0};for(int s=0;s<2;s++)for(size_t i=0;i<n;i++)parent[s][i]=-1;seen[0][start]=seen[1][target]=1;q[0][tail[0]++]=start;q[1][tail[1]++]=target;int meet=-1;
  while(tail[0]>head[0]&&tail[1]>head[1]&&meet<0){int end=tail[0];for(;head[0]<end;head[0]++){int u=q[0][head[0]];for(int j=0;j<deg[u];j++){int v=adj[u][j];if(seen[0][v])continue;seen[0][v]=1;parent[0][v]=u;q[0][tail[0]++]=v;}}for(size_t v=0;v<n;v++)if(seen[0][v]&&seen[1][v]){meet=(int)v;break;}if(meet>=0)break;
   end=tail[1];for(;head[1]<end;head[1]++){int u=q[1][head[1]];for(int j=0;j<deg[u];j++){int v=adj[u][j];if(seen[1][v])continue;seen[1][v]=1;parent[1][v]=u;q[1][tail[1]++]=v;}}for(size_t v=0;v<n;v++)if(seen[0][v]&&seen[1][v]){meet=(int)v;break;}}
  if(meet>=0){int rev[MAX_VERTICES],k=0;for(int v=meet;v!=-1;v=parent[0][v])rev[k++]=v;while(k>0)path[pc++]=rev[--k];for(int v=parent[1][meet];v!=-1;v=parent[1][v])path[pc++]=v;}}
 size_t bytes=(1+pc)*8;if(!output||capacity<bytes)return -2;put(output,0,(int64_t)pc);for(size_t i=0;i<pc;i++)put(output,1+i,path[i]);return (int64_t)bytes;
}
