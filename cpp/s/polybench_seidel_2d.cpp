/* PolyBench/C seidel-2d bounded port. See benchmarks/s/polybench_seidel_2d/LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t polybench_seidel_2d(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept{
    if(!input||length!=2||!std::isfinite(input[0])||!std::isfinite(input[1])||std::trunc(input[0])!=input[0]||std::trunc(input[1])!=input[1]||input[0]<1||input[0]>6||input[1]<0||input[1]>4)return -1;
    auto n=std::size_t(input[0]),steps=std::size_t(input[1]),cells=n*n;if(!output||capacity<cells)return -2;
    double a[36]{},staged[36]{};
    for(std::size_t i=0;i<n;++i)for(std::size_t j=0;j<n;++j)a[i*n+j]=(double(i)*double(j+2)+2.0)/double(n);
    for(std::size_t t=0;t<steps;++t)for(std::size_t i=1;i+1<n;++i)for(std::size_t j=1;j+1<n;++j){auto q=i*n+j;double sum=a[q-n-1]+a[q-n]+a[q-n+1]+a[q-1]+a[q]+a[q+1]+a[q+n-1]+a[q+n]+a[q+n+1];a[q]=sum/9.0;}
    for(std::size_t q=0;q<cells;++q)staged[q]=a[q];for(std::size_t q=0;q<cells;++q)output[q]=staged[q];return std::int64_t(cells);
}
