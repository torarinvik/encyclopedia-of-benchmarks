#include <cmath>
#include <cstddef>
extern "C" long long tsvc_s2275_matrix_vector_axpy_interleave(const double*x,std::size_t l,double*y,std::size_t cap){
 if(!x||l<9||l>226)return -1;double rn=x[0],rp=x[1];if(!std::isfinite(rn)||std::trunc(rn)!=rn||rn<1||rn>8||!std::isfinite(rp)||std::trunc(rp)!=rp||rp<1||rp>8)return -1;
 auto n=(std::size_t)rn;auto passes=(std::size_t)rp;auto ms=n*n;auto out_count=ms+n;if(l!=2+3*ms+4*n)return -1;for(std::size_t i=2;i<l;i++)if(!std::isfinite(x[i])||std::trunc(x[i])!=x[i]||std::abs(x[i])>1)return -1;
 if(!y||cap<out_count)return -2;double aa[64],a[8];auto bb=2+ms;auto cc=2+2*ms;auto vec=2+3*ms;for(std::size_t i=0;i<ms;i++)aa[i]=x[2+i];for(std::size_t i=0;i<n;i++)a[i]=x[vec+i];
 for(std::size_t pass=0;pass<passes;pass++)for(std::size_t i=0;i<n;i++){for(std::size_t j=0;j<n;j++){auto k=j*n+i;aa[k]=aa[k]+x[bb+k]*x[cc+k];}a[i]=x[vec+n+i]+x[vec+2*n+i]*x[vec+3*n+i];}
 for(std::size_t i=0;i<ms;i++)y[i]=aa[i];for(std::size_t i=0;i<n;i++)y[ms+i]=a[i];return static_cast<long long>(out_count);
}
