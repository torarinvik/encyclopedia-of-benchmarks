/* Compute source-zero shortest distances on a bounded connected graph. */
#include <stddef.h>
#include <stdint.h>
static void put_i64(uint8_t*out,size_t i,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;b++)out[i*8+b]=(uint8_t)(bits>>(8*b));}
int64_t dijkstra_positive_connected(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<2)return -1;int64_t nv=in[0],mv=in[1];if(nv<2||nv>4||mv<0||mv>6||len!=(size_t)(2+3*mv))return -1;int n=(int)nv,m=(int)mv;if(m<n-1||m>n*(n-1)/2)return -1;
 int weight[4][4]={{0}},adj[4][4]={{0}};int degree[4]={0},neighbors[4][6]={{0}};
 for(int e=0;e<m;e++){int64_t u=in[2+3*e],v=in[3+3*e],w=in[4+3*e];if(u<0||u>=n||v<0||v>=n||u==v||w<1||w>255||adj[u][v])return -1;adj[u][v]=adj[v][u]=1;weight[u][v]=weight[v][u]=(int)w;neighbors[u][degree[u]++]=(int)v;neighbors[v][degree[v]++]=(int)u;}
 int seen[4]={0},stack[4],top=0;stack[top++]=0;seen[0]=1;while(top){int u=stack[--top];for(int i=0;i<degree[u];i++){int v=neighbors[u][i];if(!seen[v]){seen[v]=1;stack[top++]=v;}}}for(int i=0;i<n;i++)if(!seen[i])return -1;
 int64_t dist[4]={INT64_MAX,INT64_MAX,INT64_MAX,INT64_MAX};int done[4]={0};dist[0]=0;for(int step=0;step<n;step++){int u=-1;for(int i=0;i<n;i++)if(!done[i]&&(u<0||dist[i]<dist[u]))u=i;if(u<0)break;done[u]=1;for(int j=0;j<degree[u];j++){int v=neighbors[u][j];if(!done[v]&&dist[u]+weight[u][v]<dist[v])dist[v]=dist[u]+weight[u][v];}}
 if(!out||cap<(size_t)n*8)return -2;for(int i=0;i<n;i++)put_i64(out,i,dist[i]);return (int64_t)n*8;
}
