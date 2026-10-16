#include <stddef.h>
#include <stdint.h>
static int64_t power(int64_t a,int64_t e,int64_t m){if(e==0)return 1;if(e&1)return (power(a,e-1,m)*a)%m;int64_t h=power(a,e/2,m);return (h*h)%m;}
int64_t modular_binary_exponentiation_recursive(const int64_t*v,size_t n){if(!v||n!=3)return -1;int64_t a=v[0],e=v[1],m=v[2];if(a<0||a>1000000||e<0||e>60||m<2||m>1000000)return -1;return power(a,e,m);}
