/* PolyBench/C seidel-2d bounded port. See benchmarks/s/polybench_seidel_2d/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 6
int64_t polybench_seidel_2d(const double* input,size_t length,double* output,size_t capacity){
    if(!input||length!=2||!isfinite(input[0])||!isfinite(input[1])||trunc(input[0])!=input[0]||trunc(input[1])!=input[1]||input[0]<1||input[0]>MAX_N||input[1]<0||input[1]>4)return -1;
    size_t n=(size_t)input[0],steps=(size_t)input[1],cells=n*n;
    if(!output||capacity<cells)return -2;
    double a[36]={0},staged[36]={0};
    for(size_t i=0;i<n;++i)for(size_t j=0;j<n;++j)a[i*n+j]=((double)i*(double)(j+2)+2.0)/(double)n;
    for(size_t t=0;t<steps;++t)for(size_t i=1;i+1<n;++i)for(size_t j=1;j+1<n;++j){size_t q=i*n+j;double sum=a[q-n-1]+a[q-n]+a[q-n+1]+a[q-1]+a[q]+a[q+1]+a[q+n-1]+a[q+n]+a[q+n+1];a[q]=sum/9.0;}
    for(size_t q=0;q<cells;++q)staged[q]=a[q];for(size_t q=0;q<cells;++q)output[q]=staged[q];return (int64_t)cells;
}
