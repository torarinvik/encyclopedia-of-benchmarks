#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
double pow_algorithm(const int64_t *v,size_t n){if(!v||n!=2||v[0]<-1000||v[0]>1000||v[1]<-8||v[1]>12)return INVALID_RESULT;double result=1.0;for(int64_t i=1;i<=v[1];i++)result*=(double)v[0];return result;}
