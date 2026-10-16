#include <stddef.h>
#include <stdint.h>
int64_t permutation_and_combination(const int64_t*v,size_t n){if(!v||n!=3)return -1;int64_t op=v[0],a=v[1],r=v[2];if(op<0||op>2||a<0||a>18)return -1;if(op==0){r=0;}else if(r<0||r>a)return -1;int64_t result=1;if(op==0){for(int64_t i=2;i<=a;i++)result*=i;}else if(op==1){for(int64_t i=a-r+1;i<=a;i++)result*=i;}else{if(r>a-r)r=a-r;for(int64_t i=1;i<=r;i++)result=result*(a-r+i)/i;}return result;}
