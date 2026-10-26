#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, int64_t x) { uint64_t b=(uint64_t)x; for(size_t i=0;i<8;i++) out[i]=(uint8_t)(b>>(8*i)); }

int64_t all_distances_sketch_bottom_k(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if(!input||length<6||length>104)return -1;
    int64_t n0=input[0],m0=input[1],k0=input[2],s0=input[3];
    if(n0<2||n0>10||m0<0||m0>n0*(n0-1)||k0<1||k0>n0||s0<0||s0>=n0||length!=4+(size_t)n0+2*(size_t)m0)return -1;
    size_t n=(size_t)n0,m=(size_t)m0,k=(size_t)k0,source=(size_t)s0;
    uint8_t used[10]={0}; int64_t rank[10];
    for(size_t i=0;i<n;i++){int64_t r=input[4+i];if(r<0||r>=n0||used[r])return -1;used[r]=1;rank[i]=r;}
    uint8_t adj[10][10]={{0}};
    for(size_t e=0;e<m;e++){int64_t u0=input[4+n+2*e],v0=input[5+n+2*e];if(u0<0||u0>=n0||v0<0||v0>=n0||u0==v0)return -1;size_t u=(size_t)u0,v=(size_t)v0;if(adj[u][v])return -1;adj[u][v]=1;}
    int64_t dist[10];for(size_t i=0;i<n;i++)dist[i]=-1;size_t queue[10],head=0,tail=0;dist[source]=0;queue[tail++]=source;
    while(head<tail){size_t u=queue[head++];for(size_t v=0;v<n;v++)if(adj[u][v]&&dist[v]<0){dist[v]=dist[u]+1;queue[tail++]=v;}}
    int64_t staged[21];size_t count=0;
    for(size_t d=0;d<n;d++)for(size_t v=0;v<n;v++)if(dist[v]==(int64_t)d){
        size_t smaller=0;for(size_t x=0;x<n;x++)if(dist[x]>=0&&(dist[x]<dist[v]||(dist[x]==dist[v]&&x<=v))&&rank[x]<rank[v])smaller++;
        if(smaller<k){staged[1+2*count]=(int64_t)v;staged[2+2*count]=dist[v];count++;}
    }
    staged[0]=(int64_t)count;size_t words=1+2*count,bytes=8*words;
    if(!output||capacity<bytes)return -2;
    for(size_t i=0;i<words;i++)put_i64(output+8*i,staged[i]);return (int64_t)bytes;
}
