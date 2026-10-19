/* PolyBench/C lu bounded port. See benchmarks/l/polybench_lu/LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t polybench_lu(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept {
    if(!input||length!=1||!std::isfinite(input[0])||std::trunc(input[0])!=input[0]||input[0]<1||input[0]>6)return -1;
    auto n=std::size_t(input[0]),cells=n*n;if(!output||capacity<cells)return -2;
    double a[36]{},base[36]{},staged[36]{};
    for(std::size_t i=0;i<n;++i){for(std::size_t j=0;j<=i;++j)base[i*n+j]=1.0-double(j)/double(n);base[i*n+i]=1.0;}
    for(std::size_t t=0;t<n;++t)for(std::size_t r=0;r<n;++r)for(std::size_t s=0;s<n;++s)a[r*n+s]+=base[r*n+t]*base[s*n+t];
    for(std::size_t i=0;i<n;++i){for(std::size_t j=0;j<i;++j){for(std::size_t k=0;k<j;++k)a[i*n+j]-=a[i*n+k]*a[k*n+j];a[i*n+j]/=a[j*n+j];}for(std::size_t j=i;j<n;++j)for(std::size_t k=0;k<i;++k)a[i*n+j]-=a[i*n+k]*a[k*n+j];}
    for(std::size_t q=0;q<cells;++q)staged[q]=a[q];for(std::size_t q=0;q<cells;++q)output[q]=staged[q];return std::int64_t(cells);
}
