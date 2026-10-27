#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 24
#define MAX_INPUT 74

static void put32(uint8_t *out, size_t pos, int32_t value) {
    uint32_t bits=(uint32_t)value;
    for(size_t j=0;j<4;++j){out[pos+j]=(uint8_t)(bits&255U);bits>>=8;}
}

int64_t randomized_contraction_edge_sampling(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if(!input||length<5||length>MAX_INPUT)return -1;
    int64_t n64=input[0],m64=input[1];
    if(n64<2||n64>MAX_N||m64<n64-1||m64>MAX_M||length!=2+3*(size_t)m64)return -1;
    size_t n=(size_t)n64,m=(size_t)m64;
    int64_t u[MAX_M],v[MAX_M],bit[MAX_M];
    for(size_t i=0;i<m;++i){
        u[i]=input[2+3*i];v[i]=input[3+3*i];bit[i]=input[4+3*i];
        if(u[i]<0||u[i]>=v[i]||v[i]>=n64||(bit[i]!=0&&bit[i]!=1))return -1;
        for(size_t j=0;j<i;++j)if(u[i]==u[j]&&v[i]==v[j])return -1;
    }
    uint8_t seen[MAX_N]={0};size_t queue[MAX_N],head=0,tail=0;
    queue[tail++]=0;seen[0]=1;
    while(head<tail){size_t current=queue[head++];for(size_t e=0;e<m;++e){int64_t next=-1;if((size_t)u[e]==current)next=v[e];else if((size_t)v[e]==current)next=u[e];if(next>=0&&!seen[(size_t)next]){seen[(size_t)next]=1;queue[tail++]=(size_t)next;}}}
    if(tail!=n)return -1;
    size_t parent[MAX_N];for(size_t i=0;i<n;++i)parent[i]=i;
    for(size_t e=0;e<m;++e)if(bit[e]){size_t a=(size_t)u[e],b=(size_t)v[e];while(parent[a]!=a)a=parent[a];while(parent[b]!=b)b=parent[b];if(a!=b)parent[b]=a;}
    size_t minimum[MAX_N];for(size_t i=0;i<n;++i)minimum[i]=n;
    for(size_t vertex=0;vertex<n;++vertex){size_t root=vertex;while(parent[root]!=root)root=parent[root];if(vertex<minimum[root])minimum[root]=vertex;}
    size_t bytes=4*n;if(!output||capacity<bytes)return -2;
    uint8_t staged[4*MAX_N];
    for(size_t vertex=0;vertex<n;++vertex){size_t root=vertex;while(parent[root]!=root)root=parent[root];put32(staged,4*vertex,(int32_t)minimum[root]);}
    for(size_t i=0;i<bytes;++i)output[i]=staged[i];
    return (int64_t)bytes;
}
