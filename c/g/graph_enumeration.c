#include <stdint.h>
#include <stddef.h>
#include <limits.h>
int64_t graph_enumeration(const int64_t *a, size_t length) {
    if (!a || length < 1) return -1;
    int64_t n0=a[0]; if(n0<0||n0>16||length<(size_t)(1+n0))return -1;
    size_t n=(size_t)n0, off=1+n; int64_t labels[16], ordered[16]; size_t ord[16];
    for(size_t i=0;i<n;i++){labels[i]=a[1+i];if(labels[i]<-1000000||labels[i]>1000000)return -1;for(size_t j=0;j<i;j++)if(labels[i]==labels[j])return -1;ordered[i]=labels[i];}
    for(size_t i=0;i<n;i++)for(size_t j=i+1;j<n;j++)if(ordered[j]<ordered[i]){int64_t t=ordered[i];ordered[i]=ordered[j];ordered[j]=t;}
    for(size_t i=0;i<n;i++){ord[i]=0;while(ord[i]<n&&ordered[ord[i]]!=labels[i])ord[i]++;}
    int64_t adjacency[16][32]; size_t degree[16];
    for(size_t i=0;i<n;i++){
        if(off>=length)return -1;int64_t d0=a[off++];if(d0<0||d0>32||off+(size_t)d0>length)return -1;degree[i]=(size_t)d0;
        for(size_t j=0;j<degree[i];j++){int64_t x=a[off++];size_t k=0;while(k<n&&labels[k]!=x)k++;if(k==n)return -1;adjacency[i][j]=x;}
    }
    if(off!=length)return -1;
    uint64_t h=14695981039346656037ULL;
#define MIX(v) do { uint64_t z=(uint64_t)(v); for(int b=0;b<8;b++){h=(h^(z&255))*1099511628211ULL;z>>=8;} } while(0)
    MIX(n+1); MIX(0);
    for(size_t s=0;s<n;s++){size_t i=0;while(i<n&&labels[i]!=ordered[s])i++;MIX(degree[i]);for(size_t j=0;j<degree[i];j++){size_t k=0;while(labels[k]!=adjacency[i][j])k++;MIX(ord[k]+1);}}
    return (int64_t)h;
}
