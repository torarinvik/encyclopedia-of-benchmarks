#include <cstddef>
#include <cstdint>
#include <climits>
static int32_t bound_shift(int32_t x){int32_t s=static_cast<int32_t>(static_cast<uint32_t>(x)<<1);return s<0?s+1:INT32_MAX;}
static int cmp(int64_t x,int64_t y){return (x>y)-(x<y);}
static void left_run(const int64_t*a,int64_t k,int64_t b,int64_t h,int64_t&o,int64_t&l){auto m=h+1,x=int64_t(1),t=int64_t(0);while(x<m&&k<a[b+h-x]){t=x;x=bound_shift(static_cast<int32_t>(x));}if(x>m)x=m;l=h-x;o=h-t;}
static void right_run(const int64_t*a,int64_t k,int64_t b,int64_t n,int64_t h,int64_t&o,int64_t&l){auto x=int64_t(1),last=int64_t(0),m=n-h;while(x<m&&k>a[b+h+x]){last=x;x=bound_shift(static_cast<int32_t>(x));}if(x>m)x=m;o=x+h;l=last+h;}
static int64_t final_offset(const int64_t*a,int64_t k,int64_t b,int64_t o,int64_t l,int lt){++l;while(l<o){auto mid=l+((static_cast<uint64_t>(o-l))>>1);if(cmp(k,a[b+mid])<lt)o=mid;else l=mid+1;}return o;}
extern "C" int64_t galloping_strategy(const int64_t*v,std::size_t n){if(!v||n<5||n>69)return -1;auto op=v[0],count=v[1],base=v[2],len=v[3],key=v[4];if((op!=0&&op!=1)||count<0||count>64||n!=5+static_cast<std::size_t>(count)||base<0||len<0||base>count||len>count-base||key<INT32_MIN||key>INT32_MAX)return -1;auto a=v+5;for(int64_t i=0;i<count;i++)if(a[i]<INT32_MIN||a[i]>INT32_MAX)return -1;if(count==0)return 0;if(len==0||base>=count)return -1;for(int64_t i=base;i+1<base+len;i++)if(a[i]>a[i+1])return -1;int64_t o,l;if(op==0){if(key>a[base])right_run(a,key,base,len,0,o,l);else left_run(a,key,base,0,o,l);return final_offset(a,key,base,o,l,1);}if(key<a[base])left_run(a,key,base,len,o,l);else right_run(a,key,base,len,0,o,l);return final_offset(a,key,base,o,l,0);}
