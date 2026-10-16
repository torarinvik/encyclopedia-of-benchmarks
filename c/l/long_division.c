#include <stddef.h>
#include <stdint.h>
static int64_t core(int64_t a,int64_t b){if(b==0)return 0;int neg=(a<0)!=(b<0);if(a<0)a=-a;if(b<0)b=-b;int64_t digits[16];size_t n=0;if(a==0)digits[n++]=0;while(a){digits[n++]=a%10;a/=10;}int64_t rem=0,q=0;for(size_t i=n;i>0;i--){rem=rem*10+digits[i-1];int64_t d=0;while(rem>=b){rem-=b;d++;}q=q*10+d;}return neg?-q:q;}
int64_t long_division(const int64_t*v,size_t n){if(!v||n!=2||v[0]<-1000000||v[0]>1000000||v[1]<-10000||v[1]>10000)return -1;return core(v[0],v[1]);}
