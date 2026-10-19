/* PolyBench/C correlation kernel, bounded port. See benchmarks/c/polybench_correlation/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 6
#define MAX_M 6
int64_t polybench_correlation(const double* input,size_t length,double* output,size_t capacity){
    if(!input||length!=2||!isfinite(input[0])||!isfinite(input[1])||trunc(input[0])!=input[0]||trunc(input[1])!=input[1]||input[0]<1||input[0]>MAX_N||input[1]<1||input[1]>MAX_M)return -1;
    size_t n=(size_t)input[0],m=(size_t)input[1],required=m*m;
    if(!output||capacity<required)return -2;
    double data[36]={0},corr[36]={0},mean[6]={0},stddev[6]={0},staged[36]={0},float_n=(double)n;
    for(size_t i=0;i<n;++i)for(size_t j=0;j<m;++j)data[i*m+j]=(double)(i*j)/(double)m+(double)i;
    for(size_t j=0;j<m;++j){mean[j]=0.0;for(size_t i=0;i<n;++i)mean[j]+=data[i*m+j];mean[j]/=float_n;}
    for(size_t j=0;j<m;++j){stddev[j]=0.0;for(size_t i=0;i<n;++i){double d=data[i*m+j]-mean[j];stddev[j]+=d*d;}stddev[j]/=float_n;stddev[j]=sqrt(stddev[j]);stddev[j]=stddev[j]<=0.1?1.0:stddev[j];}
    double scale=sqrt(float_n);
    for(size_t i=0;i<n;++i)for(size_t j=0;j<m;++j){data[i*m+j]-=mean[j];data[i*m+j]/=scale*stddev[j];}
    for(size_t i=0;i+1<m;++i){corr[i*m+i]=1.0;for(size_t j=i+1;j<m;++j){corr[i*m+j]=0.0;for(size_t k=0;k<n;++k)corr[i*m+j]+=data[k*m+i]*data[k*m+j];corr[j*m+i]=corr[i*m+j];}}
    corr[(m-1)*m+m-1]=1.0;
    for(size_t q=0;q<required;++q)staged[q]=corr[q];for(size_t q=0;q<required;++q)output[q]=staged[q];return (int64_t)required;
}
