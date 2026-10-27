#include <stddef.h>
#include <stdint.h>

#define MAX_TOTAL 8
#define MAX_M 7
#define MAX_INPUT 75

static void put(uint8_t *o,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){o[at+i]=(uint8_t)(b&255U);b>>=8;}}
static int lex_less(uint32_t a,uint32_t b,size_t m){size_t i=0,j=0;for(;;){while(i<m&&!(a&(1U<<i)))++i;while(j<m&&!(b&(1U<<j)))++j;if(i==m||j==m)return i==m&&j!=m;if(i!=j)return i<j;++i;++j;}}
static int64_t cost(size_t n,size_t m,const int64_t d[MAX_TOTAL][MAX_TOTAL],const int64_t *fee,uint32_t mask){
    int64_t x=0;size_t q=n+m;for(size_t j=0;j<m;++j)if(mask&(1U<<j))x+=fee[j];
    for(size_t u=0;u<n;++u){int64_t best=INT64_MAX;for(size_t j=0;j<m;++j)if(mask&(1U<<j)){int64_t v=d[u][n+j];if(v<best)best=v;}x+=best;}return x;
}
static void consider(uint32_t candidate,size_t n,size_t m,const int64_t d[MAX_TOTAL][MAX_TOTAL],const int64_t *fee,uint32_t *best,int64_t *best_cost){
    int64_t c=cost(n,m,d,fee,candidate);if(c<*best_cost||(c==*best_cost&&lex_less(candidate,*best,m))){*best=candidate;*best_cost=c;}
}

int64_t facility_location_add_delete_swap(const int64_t *in,size_t len,uint8_t *out,size_t cap){
    if(!in||len<4||len>MAX_INPUT)return -1;int64_t n0=in[0],m0=in[1];if(n0<1||m0<1||n0+m0>MAX_TOTAL||n0>7||m0>7)return -1;
    size_t n=(size_t)n0,m=(size_t)m0,q=n+m;if(len!=2+q*q+m+1)return -1;
    int64_t d[MAX_TOTAL][MAX_TOTAL]={{0}},fee[MAX_M];size_t p=2;
    for(size_t i=0;i<q;++i)for(size_t j=0;j<q;++j){int64_t v=in[p++];if(v<0||v>1000)return -1;d[i][j]=v;}
    for(size_t i=0;i<q;++i){if(d[i][i]!=0)return -1;for(size_t j=0;j<q;++j){if(i!=j&&d[i][j]<=0)return -1;if(d[i][j]!=d[j][i])return -1;for(size_t k=0;k<q;++k)if(d[i][j]>d[i][k]+d[k][j])return -1;}}
    for(size_t j=0;j<m;++j){fee[j]=in[p++];if(fee[j]<0||fee[j]>1000)return -1;}
    int64_t initial=in[p];if(initial<=0||(uint64_t)initial>=(UINT64_C(1)<<m))return -1;uint32_t current=(uint32_t)initial;
    int64_t current_cost=cost(n,m,d,fee,current);
    for(size_t pass=0;pass<(UINT32_C(1)<<m);++pass){uint32_t best=current;int64_t best_cost=current_cost;
        for(size_t j=0;j<m;++j){uint32_t bit=UINT32_C(1)<<j;if(!(current&bit))consider(current|bit,n,m,d,fee,&best,&best_cost);
            else{if(current&~bit){consider(current&~bit,n,m,d,fee,&best,&best_cost);for(size_t k=0;k<m;++k){uint32_t other=UINT32_C(1)<<k;if(!(current&other))consider((current&~bit)|other,n,m,d,fee,&best,&best_cost);}}}}
        if(best_cost*10>=current_cost*9)break;current=best;current_cost=best_cost;
    }
    size_t count=0;for(size_t j=0;j<m;++j)if(current&(UINT32_C(1)<<j))++count;
    size_t out_bytes=8*(2+n+count);if(!out||cap<out_bytes)return -2;
    put(out,0,current_cost);put(out,8,(int64_t)count);size_t at=16;
    for(size_t j=0;j<m;++j)if(current&(UINT32_C(1)<<j)){put(out,at,(int64_t)j);at+=8;}
    for(size_t u=0;u<n;++u){size_t best=0;int64_t dist=INT64_MAX;for(size_t j=0;j<m;++j)if(current&(UINT32_C(1)<<j)){int64_t v=d[u][n+j];if(v<dist){dist=v;best=j;}}put(out,at,(int64_t)best);at+=8;}
    return (int64_t)at;
}
