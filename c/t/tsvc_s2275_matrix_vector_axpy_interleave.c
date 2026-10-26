#include <math.h>
#include <stddef.h>
long long tsvc_s2275_matrix_vector_axpy_interleave(const double*x,size_t l,double*y,size_t cap){
 if(!x||l<9||l>226)return -1;double rn=x[0],rp=x[1];
 if(!isfinite(rn)||trunc(rn)!=rn||rn<1||rn>8||!isfinite(rp)||trunc(rp)!=rp||rp<1||rp>8)return -1;
 size_t n=(size_t)rn,passes=(size_t)rp,ms=n*n,out_count=ms+n;if(l!=2+3*ms+4*n)return -1;
 for(size_t i=2;i<l;i++)if(!isfinite(x[i])||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;
 if(!y||cap<out_count)return -2;double aa[64],a[8];for(size_t i=0;i<ms;i++)aa[i]=x[2+i];
 size_t bb=2+ms,cc=2+2*ms,vec=2+3*ms;
 for(size_t i=0;i<n;i++)a[i]=x[vec+i];
 for(size_t pass=0;pass<passes;pass++)for(size_t i=0;i<n;i++){for(size_t j=0;j<n;j++){size_t k=j*n+i;aa[k]=aa[k]+x[bb+k]*x[cc+k];}a[i]=x[vec+n+i]+x[vec+2*n+i]*x[vec+3*n+i];}
 for(size_t i=0;i<ms;i++)y[i]=aa[i];for(size_t i=0;i<n;i++)y[ms+i]=a[i];return (long long)out_count;
}
