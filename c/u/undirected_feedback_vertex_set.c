/* Clean-room bounded iterative-compression feedback vertex set profile. */
#include <stddef.h>
#include <stdint.h>

enum { NMAX=8, MMAX=28, IMAX=59 };
static unsigned bits(uint64_t x){unsigned n=0;while(x){n+=(unsigned)(x&1u);x>>=1;}return n;}
static size_t root(size_t parent[NMAX],size_t x){while(parent[x]!=x){parent[x]=parent[parent[x]];x=parent[x];}return x;}
static int is_forest(const uint8_t a[NMAX][NMAX],size_t n,uint64_t vertices){size_t parent[NMAX];for(size_t i=0;i<n;++i)parent[i]=i;for(size_t u=0;u<n;++u)if((vertices>>u)&1u)for(size_t v=u+1;v<n;++v)if(((vertices>>v)&1u)&&a[u][v]){size_t x=root(parent,u),y=root(parent,v);if(x==y)return 0;parent[x]=y;}return 1;}
static int compress(const uint8_t a[NMAX][NMAX],size_t n,uint64_t prefix,unsigned k,uint64_t current,uint64_t *result){
    for(uint64_t x=current;;x=(x-1)&current){unsigned cx=bits(x);uint64_t excluded=current&~x;if(cx<=k&&is_forest(a,n,excluded)){uint64_t eligible=prefix&~current;for(uint64_t s=eligible;;s=(s-1)&eligible){if(bits(s)<=k-cx&&is_forest(a,n,prefix&~(x|s))){*result=x|s;return 1;}if(s==0)break;}}if(x==0)break;}
    return 0;
}
static int solve_budget(const uint8_t a[NMAX][NMAX],size_t n,unsigned k,uint64_t *answer){uint64_t fvs=0;for(size_t i=0;i<n;++i){uint64_t prefix=(UINT64_C(1)<<(i+1))-1,candidate=fvs|(UINT64_C(1)<<i);if(bits(candidate)<=k){fvs=candidate;continue;}uint64_t compressed=0;if(!compress(a,n,prefix,k,candidate,&compressed))return 0;fvs=compressed;}*answer=fvs;return 1;}
static void put(uint8_t*out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){out[at+i]=(uint8_t)(b&255u);b>>=8;}}
int64_t undirected_feedback_vertex_set(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
    if(!input||length<3||length>IMAX)return -1;int64_t nn=input[0],mm=input[1],limit=input[2];if(nn<1||nn>8||mm<0||mm>28||limit<0||limit>4||length!=3+2*(size_t)mm)return -1;size_t n=(size_t)nn,m=(size_t)mm;
    uint8_t a[NMAX][NMAX]={{0}};int64_t pu=-1,pv=-1;for(size_t e=0;e<m;++e){int64_t u=input[3+2*e],v=input[4+2*e];if(u<0||v<=u||v>=nn||u<pu||(u==pu&&v<=pv))return -1;a[u][v]=a[v][u]=1;pu=u;pv=v;}
    if(!output||capacity<16)return -2;int found=0;unsigned minimum=0;uint64_t answer=0;for(unsigned k=0;k<=(unsigned)limit;++k){if(solve_budget(a,n,k,&answer)){found=1;minimum=k;break;}}
    put(output,0,found?1:0);put(output,8,found?(int64_t)minimum:-1);return 16;
}
