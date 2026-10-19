/* PolyBench/C fdtd-2d kernel, bounded port. See benchmarks/f/fdtd_2d/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NX 6
#define MAX_NY 6
#define MAX_TMAX 4

int64_t fdtd_2d(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    for (size_t q=0; q<3; ++q) if (!isfinite(input[q]) || trunc(input[q]) != input[q]) return -1;
    if (input[0] < 0 || input[0] > MAX_TMAX || input[1] < 1 || input[1] > MAX_NX || input[2] < 1 || input[2] > MAX_NY) return -1;
    size_t tmax=(size_t)input[0], nx=(size_t)input[1], ny=(size_t)input[2], n=nx*ny, required=3*n;
    if (output == NULL || capacity < required) return -2;
    double ex[36]={0}, ey[36]={0}, hz[36]={0}, fict[4]={0}, staged[108]={0};
    for(size_t t=0;t<tmax;++t) fict[t]=(double)t;
    for(size_t i=0;i<nx;++i) for(size_t j=0;j<ny;++j) {
        ex[i*ny+j]=(double)(i*(j+1))/(double)nx;
        ey[i*ny+j]=(double)(i*(j+2))/(double)ny;
        hz[i*ny+j]=(double)(i*(j+3))/(double)nx;
    }
    for(size_t t=0;t<tmax;++t) {
        for(size_t j=0;j<ny;++j) ey[j]=fict[t];
        for(size_t i=1;i<nx;++i) for(size_t j=0;j<ny;++j) ey[i*ny+j]=ey[i*ny+j]-0.5*(hz[i*ny+j]-hz[(i-1)*ny+j]);
        for(size_t i=0;i<nx;++i) for(size_t j=1;j<ny;++j) ex[i*ny+j]=ex[i*ny+j]-0.5*(hz[i*ny+j]-hz[i*ny+j-1]);
        for(size_t i=0;i+1<nx;++i) for(size_t j=0;j+1<ny;++j) hz[i*ny+j]=hz[i*ny+j]-0.7*((ex[i*ny+j+1]-ex[i*ny+j])+(ey[(i+1)*ny+j]-ey[i*ny+j]));
    }
    for(size_t i=0;i<n;++i){staged[i]=ex[i];staged[n+i]=ey[i];staged[2*n+i]=hz[i];}
    for(size_t i=0;i<required;++i) output[i]=staged[i];
    return (int64_t)required;
}
