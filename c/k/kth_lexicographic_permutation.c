#include <stddef.h>
#include <stdint.h>
int64_t kth_lexicographic_permutation(const int64_t*v,size_t n){if(!v||n!=2)return -1;int64_t k=v[0],m=v[1];if(m<2||m>9||k<0)return -1;int64_t fact=1;for(int64_t i=2;i<=m;i++)fact*=i;if(k>=fact)return -1;int64_t a[9],code=m;for(int64_t i=0;i<m;i++)a[i]=i;for(int64_t block=m-1;block>=1;block--){int64_t f=1;for(int64_t j=2;j<=block;j++)f*=j;int64_t idx=k/f;k%=f;code=code*10+a[idx]+1;for(int64_t j=idx;j<block;j++)a[j]=a[j+1];}return code*10+a[0]+1;}
