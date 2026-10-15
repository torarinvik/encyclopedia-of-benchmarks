#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 24
#define MAX_PATHS 1000
#define MAX_OUTPUT (8 + MAX_PATHS * (MAX_VERTICES + 1) * 8)

static void put_i64(uint8_t *out, size_t at, int64_t x) { uint64_t u=(uint64_t)x; for(int b=0;b<8;++b){out[at+b]=(uint8_t)u;u>>=8;} }
typedef struct { const int *adj; const int *degree; bool *visited; int *path; int depth; int target; int64_t *count; uint8_t *out; size_t *at; bool overflow; } Search;
static void dfs(Search *s, int u) {
    if (s->overflow) return;
    if (u == s->target) {
        if (*s->count == MAX_PATHS) { s->overflow=true; return; }
        put_i64(s->out,*s->at,s->depth); *s->at += 8;
        for(int i=0;i<s->depth;++i){put_i64(s->out,*s->at,s->path[i]);*s->at+=8;}
        ++*s->count; return;
    }
    s->visited[u]=true;
    for(int i=0;i<s->degree[u]&&!s->overflow;++i){int v=s->adj[u*MAX_EDGES+i];if(!s->visited[v]){s->path[s->depth++]=v;dfs(s,v);--s->depth;}}
    s->visited[u]=false;
}

int64_t all_paths_from_source_to_target(const int64_t *v,size_t n,uint8_t *output,size_t capacity) {
    if(!v||n<4||n>4+2*MAX_EDGES||v[0]<1||v[0]>MAX_VERTICES||v[1]<0||v[1]>MAX_EDGES)return -1;
    int vertices=(int)v[0],edges=(int)v[1];
    if(v[2]<0||v[2]>=vertices||v[3]<0||v[3]>=vertices||n!=4+2*(size_t)edges)return -1;
    int source=(int)v[2],target=(int)v[3];
    int adj[MAX_VERTICES*MAX_EDGES]={0},degree[MAX_VERTICES]={0};
    for(int e=0;e<edges;++e){int64_t a=v[4+2*e],b=v[5+2*e];if(a<0||a>=vertices||b<0||b>=vertices)return -1;adj[(int)a*MAX_EDGES+degree[(int)a]++]=(int)b;}
    uint8_t temp[MAX_OUTPUT]={0};int path[MAX_VERTICES]={0};bool visited[MAX_VERTICES]={false};int64_t count=0;size_t at=8;
    path[0]=source;Search search={adj,degree,visited,path,1,target,&count,temp,&at,false};dfs(&search,source);
    if(search.overflow)return -2;put_i64(temp,0,count);
    if(!output||capacity<at)return -2;for(size_t i=0;i<at;++i)output[i]=temp[i];return (int64_t)at;
}
