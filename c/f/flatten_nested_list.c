#include <stddef.h>
#include <stdint.h>
#define OPEN INT64_MIN
#define CLOSE (INT64_MIN + 1)
static int64_t signed_hash(uint64_t hash) {
 uint64_t sign = UINT64_C(1) << 63;
 if (hash < sign) return (int64_t)hash;
 uint64_t magnitude = UINT64_MAX - hash + 1;
 if (magnitude == sign) return INT64_MIN;
 return -(int64_t)magnitude;
}
int64_t flatten_nested_list(const int64_t *v,size_t n){
 if(!v||n==0||n>255||v[0]!=OPEN)return -1;
 int depth=0,closed=0;uint64_t h=UINT64_C(0xcbf29ce484222325);
 for(size_t i=0;i<n;i++){
  int64_t x=v[i];
  if(x==OPEN){if(closed||(depth==0&&i!=0))return -1;if(++depth>16)return -1;}
  else if(x==CLOSE){if(depth==0)return -1;if(--depth==0){closed=1;if(i!=n-1)return -1;}}
  else {if(depth==0||x< -1000000||x>1000000)return -1;uint64_t u=(uint64_t)x;for(int b=0;b<8;b++){h^=(uint8_t)(u>>(8*b));h*=UINT64_C(0x100000001b3);}}
 }
 if(depth!=0||!closed)return -1;
 return signed_hash(h);
}
