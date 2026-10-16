#include <cstddef>
#include <cstdint>
extern "C" std::int64_t kth_lexicographic_permutation(const std::int64_t*v,std::size_t n){if(!v||n!=2)return -1;auto k=v[0],m=v[1];if(m<2||m>9||k<0)return -1;std::int64_t fact=1;for(auto i=2;i<=m;i++)fact*=i;if(k>=fact)return -1;std::int64_t a[9],code=m;for(std::int64_t i=0;i<m;i++)a[i]=i;for(std::int64_t block=m-1;block>=1;--block){std::int64_t f=1;for(std::int64_t j=2;j<=block;j++)f*=j;auto idx=k/f;k%=f;code=code*10+a[idx]+1;for(auto j=idx;j<block;j++)a[j]=a[j+1];}return code*10+a[0]+1;}
