#include <stddef.h>
#include <stdint.h>
#define ADD (-9000000000000000001LL)
#define SUB (-9000000000000000002LL)
#define MUL (-9000000000000000003LL)
#define DIV (-9000000000000000004LL)
int64_t prefix_evaluator(const int64_t*v,size_t n){if(!v||n<2||n>129||v[0]<1||v[0]>128||n!=(size_t)v[0]+1)return -1;int32_t st[128];size_t sp=0;for(size_t i=n;i-->1;){int64_t t=v[i];if(t==ADD||t==SUB||t==MUL||t==DIV){if(sp<2)return -1;int32_t a=st[--sp],b=st[--sp],z;if(t==ADD)z=(int32_t)((uint32_t)a+(uint32_t)b);else if(t==SUB)z=(int32_t)((uint32_t)a-(uint32_t)b);else if(t==MUL)z=(int32_t)((uint32_t)a*(uint32_t)b);else{if(!b)return -1;z=(a==INT32_MIN&&b==-1)?INT32_MIN:a/b;}st[sp++]=z;}else{if(t<INT32_MIN||t>INT32_MAX||sp>=128)return -1;st[sp++]=(int32_t)t;}}return sp==1?st[0]:-1;}
