#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
#define MAX_DIM 64
double gradient_descent(const int64_t *v, size_t n) {
 if (!v || n < 5 || n > 68) return INVALID_RESULT;
 int64_t d=v[0], selected=v[1], rate=v[2], iterations=v[3];
 if (d<1 || d>MAX_DIM || selected<0 || selected>=d || n!=(size_t)(4+d) || rate<1 || rate>500000 || iterations<0 || iterations>10000) return INVALID_RESULT;
 double x[MAX_DIM]; for (int64_t i=0;i<d;i++) { if(v[4+i]<-10 || v[4+i]>10) return INVALID_RESULT; x[i]=(double)v[4+i]; }
 double alpha=(double)rate/1000000.0;
 for(int64_t k=0;k<iterations;k++) { double g[MAX_DIM]; for(int64_t i=0;i<d;i++) g[i]=2.0*x[i]; for(int64_t i=0;i<d;i++) x[i]-=alpha*g[i]; }
 return x[selected];
}
