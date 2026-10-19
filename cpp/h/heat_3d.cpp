/* PolyBench/C heat-3d bounded port. See benchmarks/h/heat_3d/LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t polybench_heat_3d(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept {
    if(!input||length!=2)return -1;
    if(!std::isfinite(input[0])||!std::isfinite(input[1])||std::trunc(input[0])!=input[0]||std::trunc(input[1])!=input[1]||input[0]<1||input[0]>6||input[1]<0||input[1]>4)return -1;
    auto n=std::size_t(input[0]),steps=std::size_t(input[1]),cells=n*n*n;
    if(!output||capacity<cells)return -2;
    double a[216]{},b[216]{},staged[216]{};
    for(std::size_t i=0;i<n;++i)for(std::size_t j=0;j<n;++j)for(std::size_t k=0;k<n;++k){auto q=i*n*n+j*n+k;a[q]=b[q]=double(i+j+(n-k))*10.0/double(n);}
    for(std::size_t t=0;t<steps;++t){
        for(std::size_t i=1;i+1<n;++i)for(std::size_t j=1;j+1<n;++j)for(std::size_t k=1;k+1<n;++k){auto q=i*n*n+j*n+k;double c=a[q];b[q]=0.125*(a[q+n*n]-2.0*c+a[q-n*n])+0.125*(a[q+n]-2.0*c+a[q-n])+0.125*(a[q+1]-2.0*c+a[q-1])+c;}
        for(std::size_t i=1;i+1<n;++i)for(std::size_t j=1;j+1<n;++j)for(std::size_t k=1;k+1<n;++k){auto q=i*n*n+j*n+k;double c=b[q];a[q]=0.125*(b[q+n*n]-2.0*c+b[q-n*n])+0.125*(b[q+n]-2.0*c+b[q-n])+0.125*(b[q+1]-2.0*c+b[q-1])+c;}
    }
    for(std::size_t q=0;q<cells;++q)staged[q]=a[q];for(std::size_t q=0;q<cells;++q)output[q]=staged[q];return std::int64_t(cells);
}
