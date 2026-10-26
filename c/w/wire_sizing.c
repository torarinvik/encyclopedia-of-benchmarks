#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 6, MAX_INPUT = 17, MAX_FIELDS = 7 };
static double absd(double x) { return x < 0.0 ? -x : x; }
static void put_i64(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b){out[at+b]=(uint8_t)bits;bits>>=8;}}

int64_t wire_sizing(const int64_t *v,size_t length,uint8_t *output,size_t capacity){
 if(!v||length<7||length>MAX_INPUT||v[0]<1||v[0]>MAX_N)return -1;
 const int n=(int)v[0];const int64_t L=v[1],rd=v[2],cl=v[3],r0=v[4];
 if(L<1||L>1000||rd<1||rd>1000||cl<1||cl>1000||r0<1||r0>1000||length!=(size_t)(5+2*n))return -1;
 int64_t h[MAX_N],c[MAX_N];
 for(int i=0;i<n;++i){h[i]=v[5+i];c[i]=v[5+n+i];if(h[i]<1||h[i]>32||c[i]<1||c[i]>1000||(i&&h[i]>=h[i-1])||(i&&c[i]>=c[i-1]))return -1;}
 double phi[MAX_N][MAX_N],rho[MAX_N];
 for(int i=0;i<n;++i){rho[i]=(double)rd*(double)c[i]+(double)cl*(double)r0/(double)h[i];for(int j=0;j<n;++j){int lo=i<j?i:j,hi=i>j?i:j;phi[i][j]=(double)r0*(double)c[hi]/(double)h[lo];}}
 double best=1.0e300,best_l[MAX_N]={0};int found=0;
 const unsigned limit=1u<<(unsigned)n;
 for(unsigned mask=1;mask<limit;++mask){int ids[MAX_N],k=0;for(int i=0;i<n;++i)if(mask&(1u<<(unsigned)i))ids[k++]=i;
  double a[MAX_N+1][MAX_N+2]={{0}};
  for(int r=0;r<k;++r){for(int q=0;q<k;++q)a[r][q]=phi[ids[r]][ids[q]];a[r][k]=1.0;a[r][k+1]=-rho[ids[r]];}
  for(int q=0;q<k;++q)a[k][q]=1.0;a[k][k+1]=(double)L;
  int solvable=1;
  for(int col=0;col<=k;++col){int pivot=col;for(int r=col+1;r<=k;++r)if(absd(a[r][col])>absd(a[pivot][col]))pivot=r;if(absd(a[pivot][col])<1.0e-12){solvable=0;break;}if(pivot!=col)for(int q=col;q<=k+1;++q){double t=a[col][q];a[col][q]=a[pivot][q];a[pivot][q]=t;}double divisor=a[col][col];for(int q=col;q<=k+1;++q)a[col][q]/=divisor;for(int r=0;r<=k;++r)if(r!=col){double factor=a[r][col];for(int q=col;q<=k+1;++q)a[r][q]-=factor*a[col][q];}}
  if(!solvable)continue;double x[MAX_N]={0};for(int r=0;r<k;++r)x[ids[r]]=a[r][k+1];double lambda=a[k][k+1];int valid=1;double total=0.0;
  for(int i=0;i<n;++i){if(x[i]<-1.0e-8)valid=0;total+=x[i];double gradient=rho[i]+lambda;for(int j=0;j<n;++j)gradient+=phi[i][j]*x[j];if(!(mask&(1u<<(unsigned)i))&&gradient < -1.0e-7)valid=0;}
  if(absd(total-(double)L)>1.0e-7)valid=0;if(!valid)continue;double objective=(double)rd*(double)cl;for(int i=0;i<n;++i){objective+=rho[i]*x[i];for(int j=0;j<n;++j)objective+=0.5*x[i]*phi[i][j]*x[j];}
  if(!found||objective<best-1.0e-7){found=1;best=objective;for(int i=0;i<n;++i)best_l[i]=x[i];}
 }
 if(!found)return -1;int64_t fields[MAX_FIELDS]={0};fields[0]=(int64_t)(best*1000000.0+0.5);for(int i=0;i<n;++i){double q=best_l[i]<0.0?0.0:best_l[i];fields[i+1]=(int64_t)(q*1000000.0+0.5);}size_t bytes=8*(size_t)(n+1);uint8_t staged[8*MAX_FIELDS]={0};for(int i=0;i<n+1;++i)put_i64(staged,8*(size_t)i,fields[i]);if(!output||capacity<bytes)return -2;for(size_t i=0;i<bytes;++i)output[i]=staged[i];return (int64_t)bytes;
}
