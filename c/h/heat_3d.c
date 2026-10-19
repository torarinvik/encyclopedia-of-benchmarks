/* PolyBench/C heat-3d bounded port. See benchmarks/h/heat_3d/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 6
#define MAX_OUT 216

int64_t polybench_heat_3d(const double *input,size_t length,double *output,size_t capacity) {
    if(input==NULL||length!=2)return -1;
    if(!isfinite(input[0])||!isfinite(input[1])||trunc(input[0])!=input[0]||trunc(input[1])!=input[1]||input[0]<1||input[0]>MAX_N||input[1]<0||input[1]>4)return -1;
    size_t n=(size_t)input[0],steps=(size_t)input[1],cells=n*n*n;
    if(output==NULL||capacity<cells)return -2;
    double a[MAX_OUT]={0},b[MAX_OUT]={0},staged[MAX_OUT]={0};
    for(size_t i=0;i<n;++i)for(size_t j=0;j<n;++j)for(size_t k=0;k<n;++k)a[i*n*n+j*n+k]=b[i*n*n+j*n+k]=(double)(i+j+(n-k))*10.0/(double)n;
    for(size_t t=0;t<steps;++t){
        for(size_t i=1;i+1<n;++i)for(size_t j=1;j+1<n;++j)for(size_t k=1;k+1<n;++k){size_t q=i*n*n+j*n+k;double c=a[q];b[q]=0.125*(a[q+n*n]-2.0*c+a[q-n*n])+0.125*(a[q+n]-2.0*c+a[q-n])+0.125*(a[q+1]-2.0*c+a[q-1])+c;}
        for(size_t i=1;i+1<n;++i)for(size_t j=1;j+1<n;++j)for(size_t k=1;k+1<n;++k){size_t q=i*n*n+j*n+k;double c=b[q];a[q]=0.125*(b[q+n*n]-2.0*c+b[q-n*n])+0.125*(b[q+n]-2.0*c+b[q-n])+0.125*(b[q+1]-2.0*c+b[q-1])+c;}
    }
    for(size_t q=0;q<cells;++q)staged[q]=a[q];
    for(size_t q=0;q<cells;++q)output[q]=staged[q];
    return (int64_t)cells;
}
