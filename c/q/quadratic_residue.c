#include <stddef.h>
#include <stdint.h>
static int prime(int64_t p){const int64_t a[]={3,5,7,11,13,17,19,23,29,31,37,41,43,47,53};for(size_t i=0;i<15;i++)if(p==a[i])return 1;return 0;}
int64_t quadratic_residue(const int64_t *in,size_t n){if(!in||n!=2)return -1;int64_t a=in[0],p=in[1];if(!prime(p)||a<0||a>=p)return -1;if(a==0)return 0;int64_t r=1,b=a,e=(p-1)/2;while(e){if(e&1)r=(r*b)%p;b=(b*b)%p;e>>=1;}return r==1?1:-1;}
