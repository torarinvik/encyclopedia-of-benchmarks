#include <stddef.h>
#include <stdint.h>
double laplacian_filter(const int64_t *v, size_t n) { if (n != 9) return -1.0e300; for (size_t i=0;i<n;i++) if(v[i]<0||v[i]>255) return -1.0e300; return (double)(4*v[4]-v[1]-v[3]-v[5]-v[7]); }
