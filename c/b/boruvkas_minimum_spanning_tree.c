#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 64
#define NO_EDGE INT64_MAX

static int find_root(int parent[MAX_N], int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

/* Boruvka MST total for a bounded connected undirected edge list. */
int64_t boruvkas_minimum_spanning_tree(const int64_t *input, size_t length) {
    if (!input || length < 2) return -1;
    int64_t nv=input[0], mv=input[1];
    if (nv<2 || nv>MAX_N || mv<nv-1 || mv>MAX_M || mv>nv*(nv-1)/2) return -1;
    int n=(int)nv, m=(int)mv;
    if (length!=(size_t)(2+3*m)) return -1;
    int64_t weight[MAX_N][MAX_N];
    for(int i=0;i<n;i++) for(int j=0;j<n;j++) weight[i][j]=NO_EDGE;
    for(int k=0;k<m;k++) {
        int64_t u=input[2+3*k],v=input[3+3*k],w=input[4+3*k];
        if(u<1||u>nv||v<1||v>nv||u==v||w<1||w>100||weight[u-1][v-1]!=NO_EDGE) return -1;
        weight[u-1][v-1]=weight[v-1][u-1]=w;
    }
    int parent[MAX_N],components=n; for(int i=0;i<n;i++) parent[i]=i;
    int64_t total=0;
    while(components>1) {
        int best_u[MAX_N],best_v[MAX_N]; int64_t best_w[MAX_N];
        for(int i=0;i<n;i++){best_u[i]=-1;best_v[i]=-1;best_w[i]=NO_EDGE;}
        for(int u=0;u<n;u++) for(int v=u+1;v<n;v++) if(weight[u][v]!=NO_EDGE) {
            int ru=find_root(parent,u),rv=find_root(parent,v);
            if(ru!=rv) {
                if(weight[u][v]<best_w[ru]){best_w[ru]=weight[u][v];best_u[ru]=u;best_v[ru]=v;}
                if(weight[u][v]<best_w[rv]){best_w[rv]=weight[u][v];best_u[rv]=u;best_v[rv]=v;}
            }
        }
        int merged=0;
        for(int r=0;r<n;r++) if(best_u[r]>=0) {
            int a=find_root(parent,best_u[r]),b=find_root(parent,best_v[r]);
            if(a!=b){parent[a]=b;components--;total+=best_w[r];merged=1;}
        }
        if(!merged) return -1;
    }
    return total;
}
