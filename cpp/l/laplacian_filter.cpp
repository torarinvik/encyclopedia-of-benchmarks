#include <cstddef>
#include <cstdint>
double laplacian_filter(const std::int64_t *v, std::size_t n) { if(n!=9)return -1.0e300; for(std::size_t i=0;i<n;i++)if(v[i]<0||v[i]>255)return -1.0e300; return static_cast<double>(4*v[4]-v[1]-v[3]-v[5]-v[7]); }
