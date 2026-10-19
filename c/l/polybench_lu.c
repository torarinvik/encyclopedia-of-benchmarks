/* PolyBench/C lu kernel, bounded port. See benchmarks/l/polybench_lu/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 6
#define MAX_CELLS 36
int64_t polybench_lu(const double *input,size_t length,double *output,size_t capacity){
    if(input==NULL||length!=1||!isfinite(input[0])||trunc(input[0])!=input[0]||input[0]<1||input[0]>MAX_N)return -1;
    size_t n=(size_t)input[0],cells=n*n;
    if(output==NULL||capacity<cells)return -2;
    double a[MAX_CELLS]={0},base[MAX_CELLS]={0},staged[MAX_CELLS]={0};
    for(size_t i=0;i<n;++i){for(size_t j=0;j<=i;++j)base[i*n+j]=1.0-(double)j/(double)n;base[i*n+i]=1.0;}
    for(size_t t=0;t<n;++t)for(size_t r=0;r<n;++r)for(size_t s=0;s<n;++s)a[r*n+s]+=base[r*n+t]*base[s*n+t];
    for(size_t i=0;i<n;++i){
        for(size_t j=0;j<i;++j){for(size_t k=0;k<j;++k)a[i*n+j]-=a[i*n+k]*a[k*n+j];a[i*n+j]/=a[j*n+j];}
        for(size_t j=i;j<n;++j)for(size_t k=0;k<i;++k)a[i*n+j]-=a[i*n+k]*a[k*n+j];
    }
    for(size_t q=0;q<cells;++q)staged[q]=a[q];for(size_t q=0;q<cells;++q)output[q]=staged[q];return (int64_t)cells;
}
