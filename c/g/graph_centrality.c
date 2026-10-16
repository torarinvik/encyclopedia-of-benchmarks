#include <stddef.h>
#include <stdint.h>

#define NMAX 16
#define INF INT64_MAX

static void put64(uint8_t *out, size_t at, int64_t v) {
    uint64_t bits = (uint64_t)v;
    for (int b = 0; b < 8; ++b) out[at * 8 + (size_t)b] = (uint8_t)(bits >> (8 * b));
}

int64_t graph_centrality(const int64_t *in, size_t len, uint8_t *out, size_t cap) {
    if (!in || len < 2) return -1;
    int64_t nn = in[0], ee = in[1];
    if (nn < 1 || nn > NMAX || ee < 0 || ee > nn * (nn - 1) || len != 2 + 3 * (size_t)ee) return -1;
    int n = (int)nn, e = (int)ee;
    int64_t d[NMAX][NMAX];
    for (int i=0;i<n;++i) for(int j=0;j<n;++j) d[i][j]=i==j?0:INF;
    for (int x=0;x<e;++x) {
        int64_t a=in[2+3*x], b=in[3+3*x], w=in[4+3*x];
        if(a<0||a>=n||b<0||b>=n||a==b||w<1||w>1000000||d[a][b]!=INF) return -1;
        d[a][b]=w;
    }
    for(int k=0;k<n;++k) for(int i=0;i<n;++i) if(d[i][k]!=INF) for(int j=0;j<n;++j) if(d[k][j]!=INF && d[i][k]+d[k][j]<d[i][j]) d[i][j]=d[i][k]+d[k][j];
    int64_t central=-1, median=-1, best_e=INF;
    double best_h=-1.0;
    if(n==1) central=median=0;
    else for(int i=0;i<n;++i) {
        int reachable=0; int64_t ecc=0; double harmonic=0.0;
        for(int j=0;j<n;++j) if(i!=j&&d[i][j]!=INF) { ++reachable; if(d[i][j]>ecc)ecc=d[i][j]; harmonic+=1.0/(double)d[i][j]; }
        if(reachable && ecc<best_e){best_e=ecc;central=i;}
        if(reachable && harmonic>best_h){best_h=harmonic;median=i;}
    }
    if(!out||cap<16)return -2;
    put64(out,0,central);put64(out,1,median);return 16;
}
