#include <stddef.h>
#include <stdint.h>
static int64_t factorial(int64_t n){int64_t x=1;for(int64_t i=1;i<=n;i++)x*=i;return x;}
int64_t permutation_calculation(const int64_t*v,size_t n){if(!v||n!=2||v[0]<0||v[0]>15||v[1]<0||v[1]>v[0])return -1;return factorial(v[0])/factorial(v[0]-v[1]);}
