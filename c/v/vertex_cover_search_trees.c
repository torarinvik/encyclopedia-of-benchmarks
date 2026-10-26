/* Clean-room exact branch-and-search vertex-cover profile. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N=16, MAX_M=64, MAX_INPUT=131 };
static unsigned popcount64(uint64_t x){unsigned n=0;while(x){n+=(unsigned)(x&1u);x>>=1;}return n;}
static uint64_t search(const uint8_t adj[MAX_N][MAX_N],size_t n,uint64_t active){
    size_t chosen=n;unsigned best_degree=0;int has_edge=0;
    for(size_t u=0;u<n;++u)if((active>>u)&1u){unsigned degree=0;for(size_t v=0;v<n;++v)if((active>>v)&1u)degree+=adj[u][v]!=0;if(degree){has_edge=1;if(chosen==n||degree>best_degree){chosen=u;best_degree=degree;}}}
    if(!has_edge)return 0;
    uint64_t bit=UINT64_C(1)<<chosen;
    uint64_t include=bit|search(adj,n,active&~bit);
    uint64_t neighbors=0;for(size_t v=0;v<n;++v)if((active>>v)&1u&&adj[chosen][v])neighbors|=UINT64_C(1)<<v;
    uint64_t exclude=neighbors|search(adj,n,active&~(neighbors|bit));
    unsigned a=popcount64(include),b=popcount64(exclude);
    return a<b?include:b<a?exclude:(include<exclude?include:exclude);
}
static void put(uint8_t*out,size_t at,int64_t x){uint64_t bits=(uint64_t)x;for(size_t b=0;b<8;++b){out[at+b]=(uint8_t)(bits&255u);bits>>=8;}}
int64_t vertex_cover_search_trees(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
    if(!input||length<3||length>MAX_INPUT)return -1;int64_t nn=input[0],mm=input[1],k=input[2];
    if(nn<1||nn>16||mm<0||mm>64||k<0||k>nn||length!=3+2*(size_t)mm)return -1;
    uint8_t adj[MAX_N][MAX_N]={{0}};int64_t pu=-1,pv=-1;
    for(size_t e=0;e<(size_t)mm;++e){int64_t u=input[3+2*e],v=input[4+2*e];if(u<0||v<=u||v>=nn||u<pu||(u==pu&&v<=pv))return -1;adj[u][v]=adj[v][u]=1;pu=u;pv=v;}
    if(!output||capacity<24)return -2;uint64_t all=(UINT64_C(1)<<(size_t)nn)-1;uint64_t cover=search(adj,(size_t)nn,all);int64_t count=(int64_t)popcount64(cover);
    put(output,0,count<=k?1:0);put(output,8,count);put(output,16,(int64_t)cover);return 24;
}
