#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 28, MAX_INPUT = 95, MAX_OUTPUT = 176 };
static void put_i64(uint8_t *out, size_t at, int64_t x) { uint64_t b=(uint64_t)x; for(size_t i=0;i<8;i++){out[at+i]=(uint8_t)(b&255);b>>=8;} }
static int find_root(int *p, int x) { while(p[x]!=x){p[x]=p[p[x]];x=p[x];} return x; }

int64_t truthful_multicast_pmst_tree(const int64_t *a, size_t n, uint8_t *out, size_t cap) {
    if(!a||n<4||n>MAX_INPUT||a[0]<2||a[0]>MAX_N||a[1]<a[0]-1||a[1]>MAX_M||a[2]<0||a[2]>=a[0]||a[3]<1||a[3]>=a[0])return -1;
    int nv=(int)a[0],m=(int)a[1],source=(int)a[2],r=(int)a[3]; if(n!=4+3*(size_t)m+(size_t)r)return -1;
    int eu[MAX_M],ev[MAX_M],ew[MAX_M],order[MAX_M],prev_u=-1,prev_v=-1;
    for(int i=0;i<m;i++){int64_t u=a[4+3*i],v=a[5+3*i],w=a[6+3*i];if(u<0||v<=u||v>=nv||w<1||w>100||(i>0&&(u<prev_u||(u==prev_u&&v<=prev_v))))return -1;eu[i]=(int)u;ev[i]=(int)v;ew[i]=(int)w;order[i]=i;prev_u=(int)u;prev_v=(int)v;}
    int receivers[MAX_N],last=-1;for(int i=0;i<r;i++){int64_t x=a[4+3*m+i];if(x<0||x>=nv||x==source||(i>0&&x<=last))return -1;receivers[i]=(int)x;last=(int)x;}
    for(int i=1;i<m;i++){int key=order[i],j=i;while(j>0){int q=order[j-1];if(ew[q]<ew[key]||(ew[q]==ew[key]&&(eu[q]<eu[key]||(eu[q]==eu[key]&&ev[q]<ev[key]))))break;order[j]=q;j--;}order[j]=key;}
    int dsu[MAX_N];for(int i=0;i<nv;i++)dsu[i]=i;int tu[MAX_N-1],tv[MAX_N-1],tw[MAX_N-1],te=0;
    for(int z=0;z<m&&te<nv-1;z++){int e=order[z],x=find_root(dsu,eu[e]),y=find_root(dsu,ev[e]);if(x!=y){dsu[x]=y;tu[te]=eu[e];tv[te]=ev[e];tw[te]=ew[e];te++;}}
    if(te!=nv-1)return -1;
    int edge_at[MAX_N][MAX_N];for(int i=0;i<nv;i++)for(int j=0;j<nv;j++)edge_at[i][j]=-1;for(int e=0;e<te;e++){edge_at[tu[e]][tv[e]]=e;edge_at[tv[e]][tu[e]]=e;}
    int parent[MAX_N],parent_edge[MAX_N],stack[MAX_N],top=0;for(int i=0;i<nv;i++){parent[i]=-1;parent_edge[i]=-1;}parent[source]=source;stack[top++]=source;
    while(top){int u=stack[--top];for(int v=0;v<nv;v++)if(edge_at[u][v]>=0&&parent[v]<0){parent[v]=u;parent_edge[v]=edge_at[u][v];stack[top++]=v;}}
    int keep[MAX_N-1]={0};for(int i=0;i<r;i++){int v=receivers[i];while(v!=source){if(parent[v]<0)return -1;keep[parent_edge[v]]=1;v=parent[v];}}
    int selected[MAX_N-1],count=0;for(int e=0;e<te;e++)if(keep[e])selected[count++]=e;
    for(int i=1;i<count;i++){int key=selected[i],j=i;while(j>0&&(tu[selected[j-1]]>tu[key]||(tu[selected[j-1]]==tu[key]&&tv[selected[j-1]]>tv[key]))){selected[j]=selected[j-1];j--;}selected[j]=key;}
    size_t bytes=8*(size_t)(1+3*count);if(!out||cap<bytes)return -2;uint8_t staged[MAX_OUTPUT];put_i64(staged,0,count);for(int i=0;i<count;i++){int e=selected[i];put_i64(staged,8*(size_t)(1+3*i),tu[e]);put_i64(staged,8*(size_t)(2+3*i),tv[e]);put_i64(staged,8*(size_t)(3+3*i),tw[e]);}for(size_t i=0;i<bytes;i++)out[i]=staged[i];return (int64_t)bytes;
}
