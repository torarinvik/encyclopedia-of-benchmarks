#include <cmath>
#include <cstddef>
extern "C" long long tsvc_s2710_nested_scalar_vector_branch_update(const double*x,std::size_t l,double*y,std::size_t cap){
 if(!x||l<58||l>323)return -1;double rn=x[0],rp=x[1],scalar=x[2];if(!std::isfinite(rn)||std::trunc(rn)!=rn||rn<11||rn>64||!std::isfinite(rp)||std::trunc(rp)!=rp||rp<1||rp>8||!std::isfinite(scalar)||std::trunc(scalar)!=scalar||std::abs(scalar)>1)return -1;
 auto n=(std::size_t)rn;auto passes=(std::size_t)rp;if(l!=3+5*n)return -1;for(std::size_t i=3;i<l;i++)if(!std::isfinite(x[i])||std::trunc(x[i])!=x[i]||std::abs(x[i])>1)return -1;if(!y||cap<3*n)return -2;
 double a[64],b[64],c[64];for(std::size_t i=0;i<n;i++){a[i]=x[3+i];b[i]=x[3+n+i];c[i]=x[3+2*n+i];}
 for(std::size_t pass=0;pass<passes;pass++)for(std::size_t i=0;i<n;i++){double d=x[3+3*n+i],e=x[3+4*n+i];if(a[i]>b[i]){a[i]+=b[i]*d;c[i]+=d*d;}else{b[i]=a[i]+e*e;if(scalar>0)c[i]=a[i]+d*d;else c[i]+=e*e;}}
 for(std::size_t i=0;i<n;i++){y[i]=a[i];y[n+i]=b[i];y[2*n+i]=c[i];}return static_cast<long long>(3*n);
}
