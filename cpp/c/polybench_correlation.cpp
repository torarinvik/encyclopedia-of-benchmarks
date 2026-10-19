/* PolyBench/C correlation bounded port. See benchmarks/c/polybench_correlation/LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t polybench_correlation(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept{
    if(!input||length!=2||!std::isfinite(input[0])||!std::isfinite(input[1])||std::trunc(input[0])!=input[0]||std::trunc(input[1])!=input[1]||input[0]<1||input[0]>6||input[1]<1||input[1]>6)return -1;
    auto n=std::size_t(input[0]),m=std::size_t(input[1]),required=m*m;if(!output||capacity<required)return -2;
    double data[36]{},corr[36]{},mean[6]{},stddev[6]{},staged[36]{},float_n=double(n);
    for(std::size_t i=0;i<n;++i)for(std::size_t j=0;j<m;++j)data[i*m+j]=double(i*j)/double(m)+double(i);
    for(std::size_t j=0;j<m;++j){mean[j]=0.0;for(std::size_t i=0;i<n;++i)mean[j]+=data[i*m+j];mean[j]/=float_n;}
    for(std::size_t j=0;j<m;++j){stddev[j]=0.0;for(std::size_t i=0;i<n;++i){double d=data[i*m+j]-mean[j];stddev[j]+=d*d;}stddev[j]/=float_n;stddev[j]=std::sqrt(stddev[j]);stddev[j]=stddev[j]<=0.1?1.0:stddev[j];}
    double scale=std::sqrt(float_n);for(std::size_t i=0;i<n;++i)for(std::size_t j=0;j<m;++j){data[i*m+j]-=mean[j];data[i*m+j]/=scale*stddev[j];}
    for(std::size_t i=0;i+1<m;++i){corr[i*m+i]=1.0;for(std::size_t j=i+1;j<m;++j){corr[i*m+j]=0.0;for(std::size_t k=0;k<n;++k)corr[i*m+j]+=data[k*m+i]*data[k*m+j];corr[j*m+i]=corr[i*m+j];}}
    corr[(m-1)*m+m-1]=1.0;for(std::size_t q=0;q<required;++q)staged[q]=corr[q];for(std::size_t q=0;q<required;++q)output[q]=staged[q];return std::int64_t(required);
}
