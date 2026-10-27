#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#define NMAX 8
#define MASKS 256

static void put64(uint8_t *o, size_t p, int64_t x) { uint64_t u=(uint64_t)x; for(size_t b=0;b<8;b++){o[p+b]=(uint8_t)u;u>>=8;} }
static size_t root(size_t *p,size_t x){while(p[x]!=x)x=p[x];return x;}
static int64_t memo[MASKS]; static int choice[MASKS]; static int64_t dd[NMAX][NMAX]; static int oddv[NMAX], oddn;
static int64_t match(int mask){
    if(mask==0)return 0;
    if(memo[mask]>=0)return memo[mask];
    int i=0;while(!(mask&(1<<i)))i++;
    int rest=mask^(1<<i);int64_t best=INT64_MAX;int bj=-1;
    for(int j=i+1;j<oddn;j++)if(rest&(1<<j)){
        int64_t v=dd[oddv[i]][oddv[j]]+match(rest^(1<<j));
        if(v<best){best=v;bj=j;}
    }
    choice[mask]=bj;memo[mask]=best;return best;
}

int64_t metric_tsp_christofides(const int64_t *in,size_t len,uint8_t *out,size_t cap){
    if(!in||len<2||len>65)return -1;int64_t n0=in[0];if(n0<1||n0>NMAX||len!=1+(size_t)n0*(size_t)n0)return -1;int n=(int)n0;
    for(int i=0;i<n;i++)for(int j=0;j<n;j++){int64_t w=in[1+i*n+j];if(w<0||w>10000||(i==j&&w!=0))return -1;dd[i][j]=w;}
    for(int i=0;i<n;i++)for(int j=0;j<n;j++){if(dd[i][j]!=dd[j][i])return -1;for(int k=0;k<n;k++)if(dd[i][j]>dd[i][k]+dd[k][j])return -1;}
    size_t bytes=8*(size_t)(n+2);if(!out||cap<bytes)return -2;
    uint8_t tree[NMAX][NMAX]={{0}}, used[NMAX][NMAX]={{0}};size_t parent[NMAX];for(int i=0;i<n;i++)parent[i]=(size_t)i;
    int edges=n*(n-1)/2, accepted=0;
    for(int step=0;step<edges&&accepted<n-1;step++){
        int bu=-1,bv=-1;int64_t bw=INT64_MAX;
        for(int u=0;u<n;u++)for(int v=u+1;v<n;v++)if(!used[u][v]&&(dd[u][v]<bw||(dd[u][v]==bw&&(bu<0||u<bu||(u==bu&&v<bv))))){bu=u;bv=v;bw=dd[u][v];}
        used[bu][bv]=1;size_t a=root(parent,(size_t)bu),b=root(parent,(size_t)bv);if(a!=b){parent[b]=a;tree[bu][bv]=tree[bv][bu]=1;accepted++;}
    }
    int deg[NMAX]={0};for(int i=0;i<n;i++)for(int j=0;j<n;j++)deg[i]+=tree[i][j];oddn=0;for(int i=0;i<n;i++)if(deg[i]&1)oddv[oddn++]=i;
    for(int i=0;i<MASKS;i++){memo[i]=-1;choice[i]=-1;}memo[0]=0;int full=(1<<oddn)-1;(void)match(full);
    uint8_t multi[NMAX][NMAX]={{0}};for(int i=0;i<n;i++)for(int j=i+1;j<n;j++)if(tree[i][j])multi[i][j]=multi[j][i]=1;
    int mask=full;while(mask){int i=0;while(!(mask&(1<<i)))i++;int j=choice[mask];int u=oddv[i],v=oddv[j];multi[u][v]++;multi[v][u]++;mask^=(1<<i)|(1<<j);}
    int stack[32],top=0,rev[32],rc=0;stack[top++]=0;
    while(top){int v=stack[top-1],w=-1;for(int x=0;x<n;x++)if(multi[v][x]){w=x;break;}if(w<0)rev[rc++]=stack[--top];else{multi[v][w]--;multi[w][v]--;stack[top++]=w;}}
    int order[NMAX],cnt=0;uint8_t seen[NMAX]={0};for(int i=rc-1;i>=0;i--)if(!seen[rev[i]]){seen[rev[i]]=1;order[cnt++]=rev[i];}
    int64_t cost=0;for(int i=0;i<n-1;i++)cost+=dd[order[i]][order[i+1]];cost+=dd[order[n-1]][0];put64(out,0,cost);for(int i=0;i<n;i++)put64(out,8*(size_t)(i+1),order[i]);put64(out,8*(size_t)(n+1),0);return (int64_t)bytes;
}
