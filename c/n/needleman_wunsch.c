#include <stddef.h>
#include <stdint.h>
#define MAX_LEN 128
#define INVALID INT64_MIN
int64_t needleman_wunsch(const int64_t *v,size_t n){
 if(!v||n<5||n>261)return INVALID;int64_t a=v[0],b=v[1],match=v[2],mismatch=v[3],gap=v[4];
 if(a<0||a>MAX_LEN||b<0||b>MAX_LEN||match<0||match>10||mismatch< -10||mismatch>0||gap< -10||gap>0||n!=5+(size_t)a+(size_t)b)return INVALID;
 for(size_t i=0;i<(size_t)a+(size_t)b;i++)if(v[5+i]<65||v[5+i]>90)return INVALID;
 int64_t dp[MAX_LEN+1];for(size_t j=0;j<=(size_t)b;j++)dp[j]=(int64_t)j*gap;
 for(size_t i=1;i<=(size_t)a;i++){int64_t diagonal=dp[0];dp[0]=(int64_t)i*gap;for(size_t j=1;j<=(size_t)b;j++){int64_t old=dp[j];int64_t score=v[5+i-1]==v[5+(size_t)a+j-1]?match:mismatch;int64_t x=diagonal+score,y=old+gap,z=dp[j-1]+gap;dp[j]=x>y?(x>z?x:z):(y>z?y:z);diagonal=old;}}return dp[b];
}
