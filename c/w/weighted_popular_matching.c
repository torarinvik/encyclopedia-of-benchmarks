/* Clean-room exhaustive solver for bounded weighted popular matchings. */
#include <stddef.h>
#include <stdint.h>
enum{MAX_N=4,MAX_FIELDS=6};
static int decode(uint64_t code,size_t n,size_t m,int*a){uint32_t used=0;for(size_t i=0;i<n;++i){size_t digit=(size_t)(code%(m+1));code/=m+1;a[i]=(int)digit-1;if(digit&&((used>>(digit-1))&1u))return 0;if(digit)used|=1u<<(digit-1);}return 1;}
static int lexless(const int*a,const int*b,size_t n){for(size_t i=0;i<n;++i)if(a[i]!=b[i])return a[i]<b[i];return 0;}
static void put(uint8_t*out,size_t at,int64_t x){uint64_t bits=(uint64_t)x;for(size_t i=0;i<8;++i){out[at+i]=(uint8_t)bits;bits>>=8;}}
int64_t weighted_popular_matching(const int64_t*v,size_t length,uint8_t*out,size_t capacity){
 if(!v||length<4||length>22||v[0]<1||v[0]>MAX_N||v[1]<1||v[1]>MAX_N)return -1;size_t n=(size_t)v[0],m=(size_t)v[1];if(length!=2+n+n*m)return -1;
 for(size_t i=0;i<n;++i){if(v[2+i]<1||v[2+i]>1000)return -1;uint32_t seen=0;for(size_t j=0;j<m;++j){int64_t r=v[2+n+i*m+j];if(r<0||r>=(int64_t)m||((seen>>(size_t)r)&1u))return -1;seen|=1u<<(size_t)r;}}
 uint64_t total=1;for(size_t i=0;i<n;++i)total*=m+1;int best_card=-1,best[MAX_N]={-1,-1,-1,-1};
 for(uint64_t code=0;code<total;++code){int cand[MAX_N]={0};if(!decode(code,n,m,cand))continue;int popular=1;
  for(uint64_t other_code=0;other_code<total&&popular;++other_code){int other[MAX_N]={0};if(!decode(other_code,n,m,other))continue;int64_t score=0;for(size_t i=0;i<n;++i){int rc=cand[i]<0?(int)m:(int)v[2+n+i*m+(size_t) cand[i]];int ro=other[i]<0?(int)m:(int)v[2+n+i*m+(size_t) other[i]];if(ro<rc)score+=v[2+i];else if(ro>rc)score-=v[2+i];}if(score>0)popular=0;}
  if(popular){int card=0;for(size_t i=0;i<n;++i)if(cand[i]>=0)++card;if(card>best_card||(card==best_card&&lexless(cand,best,n))){best_card=card;for(size_t i=0;i<n;++i)best[i]=cand[i];}}
 }
 int64_t fields[MAX_FIELDS]={0};fields[0]=best_card<0?0:1;fields[1]=best_card<0?0:best_card;for(size_t i=0;i<n;++i)fields[2+i]=best_card<0?-1:best[i];size_t bytes=8*(n+2);if(!out||capacity<bytes)return -2;for(size_t i=0;i<n+2;++i)put(out,8*i,fields[i]);return (int64_t)bytes;
}
