#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;i++)out[i]=(uint8_t)(b>>(8*i));}
static int lca(size_t n,int match[12],int parent[12],int base[12],int a,int b){uint8_t seen[12]={0};while(1){a=base[a];seen[a]=1;if(match[a]<0)break;a=parent[match[a]];}while(1){b=base[b];if(seen[b])return b;b=parent[match[b]];}}
static void mark_path(int match[12],int parent[12],int base[12],uint8_t blossom[12],int v,int b,int child){while(base[v]!=b){blossom[base[v]]=1;blossom[base[match[v]]]=1;parent[v]=child;child=match[v];v=parent[match[v]];}}
static int find_path(size_t n,uint8_t adj[12][12],int match[12],int parent[12],int base[12],int root){uint8_t used[12]={0};int queue[12],head=0,tail=0;for(size_t i=0;i<n;i++){parent[i]=-1;base[i]=(int)i;}queue[tail++]=root;used[root]=1;while(head<tail){int v=queue[head++];for(size_t ui=0;ui<n;ui++){int u=(int)ui;if(!adj[v][u]||base[v]==base[u]||match[v]==u)continue;if(u==root||(match[u]>=0&&parent[match[u]]>=0)){int cur=lca(n,match,parent,base,v,u);uint8_t blossom[12]={0};mark_path(match,parent,base,blossom,v,cur,u);mark_path(match,parent,base,blossom,u,cur,v);for(size_t i=0;i<n;i++)if(blossom[base[i]]){base[i]=cur;if(!used[i]){used[i]=1;queue[tail++]=(int)i;}}}else if(parent[u]<0){parent[u]=v;if(match[u]<0){int x=u;while(x>=0){int pv=parent[x],next=pv>=0?match[pv]:-1;if(pv>=0){match[x]=pv;match[pv]=x;}x=next;}return 1;}int mate=match[u];used[mate]=1;queue[tail++]=mate;}}}return 0;}

int64_t general_graph_maximum_matching(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<2||length>134)return -1;int64_t n0=input[0],m0=input[1];if(n0<2||n0>12||m0<0||m0>n0*(n0-1)/2||length!=2+2*(size_t)m0)return -1;size_t n=(size_t)n0,m=(size_t)m0;uint8_t adj[12][12]={{0}};
    for(size_t e=0;e<m;e++){int64_t u0=input[2+2*e],v0=input[3+2*e];if(u0<0||v0<=u0||v0>=n0)return -1;size_t u=(size_t)u0,v=(size_t)v0;if(adj[u][v])return -1;adj[u][v]=adj[v][u]=1;}
    int match[12],parent[12],base[12];for(size_t i=0;i<n;i++)match[i]=-1;for(size_t i=0;i<n;i++)if(match[i]<0)find_path(n,adj,match,parent,base,(int)i);int64_t cardinality=0;for(size_t i=0;i<n;i++)if(match[i]>(int)i)cardinality++;
    if(!output||capacity<8)return -2;put_i64(output,cardinality);return 8;
}
