/* PolyBench/C fdtd-2d bounded port. See benchmarks/f/fdtd_2d/LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t fdtd_2d(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept {
    if(!input||length!=3)return -1;
    for(std::size_t q=0;q<3;++q)if(!std::isfinite(input[q])||std::trunc(input[q])!=input[q])return -1;
    if(input[0]<0||input[0]>4||input[1]<1||input[1]>6||input[2]<1||input[2]>6)return -1;
    auto tmax=std::size_t(input[0]),nx=std::size_t(input[1]),ny=std::size_t(input[2]),n=nx*ny,required=3*n;
    if(!output||capacity<required)return -2;
    double ex[36]{},ey[36]{},hz[36]{},fict[4]{},staged[108]{};
    for(std::size_t t=0;t<tmax;++t)fict[t]=double(t);
    for(std::size_t i=0;i<nx;++i)for(std::size_t j=0;j<ny;++j){ex[i*ny+j]=double(i*(j+1))/double(nx);ey[i*ny+j]=double(i*(j+2))/double(ny);hz[i*ny+j]=double(i*(j+3))/double(nx);}
    for(std::size_t t=0;t<tmax;++t){
        for(std::size_t j=0;j<ny;++j)ey[j]=fict[t];
        for(std::size_t i=1;i<nx;++i)for(std::size_t j=0;j<ny;++j)ey[i*ny+j]=ey[i*ny+j]-0.5*(hz[i*ny+j]-hz[(i-1)*ny+j]);
        for(std::size_t i=0;i<nx;++i)for(std::size_t j=1;j<ny;++j)ex[i*ny+j]=ex[i*ny+j]-0.5*(hz[i*ny+j]-hz[i*ny+j-1]);
        for(std::size_t i=0;i+1<nx;++i)for(std::size_t j=0;j+1<ny;++j)hz[i*ny+j]=hz[i*ny+j]-0.7*((ex[i*ny+j+1]-ex[i*ny+j])+(ey[(i+1)*ny+j]-ey[i*ny+j]));
    }
    for(std::size_t i=0;i<n;++i){staged[i]=ex[i];staged[n+i]=ey[i];staged[2*n+i]=hz[i];}
    for(std::size_t i=0;i<required;++i)output[i]=staged[i];return std::int64_t(required);
}
