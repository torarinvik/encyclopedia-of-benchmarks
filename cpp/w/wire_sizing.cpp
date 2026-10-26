#include <cstddef>
#include <cstdint>
namespace {
constexpr int N=6,F=7;double absv(double x){return x<0?-x:x;}
void put(std::uint8_t*out,std::size_t at,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(int i=0;i<8;++i){out[at+i]=static_cast<std::uint8_t>(b);b>>=8;}}
}
extern "C" std::int64_t wire_sizing(const std::int64_t*v,std::size_t length,std::uint8_t*out,std::size_t cap){
 if(!v||length<7||length>17||v[0]<1||v[0]>N)return -1;const int n=static_cast<int>(v[0]);const auto L=v[1],rd=v[2],cl=v[3],r0=v[4];if(L<1||L>1000||rd<1||rd>1000||cl<1||cl>1000||r0<1||r0>1000||length!=static_cast<std::size_t>(5+2*n))return -1;
 std::int64_t h[N]{},c[N]{};for(int i=0;i<n;++i){h[i]=v[5+i];c[i]=v[5+n+i];if(h[i]<1||h[i]>32||c[i]<1||c[i]>1000||(i&&h[i]>=h[i-1])||(i&&c[i]>=c[i-1]))return -1;}
 double phi[N][N]{},rho[N]{};for(int i=0;i<n;++i){rho[i]=double(rd)*double(c[i])+double(cl)*double(r0)/double(h[i]);for(int j=0;j<n;++j){int lo=i<j?i:j,hi=i>j?i:j;phi[i][j]=double(r0)*double(c[hi])/double(h[lo]);}}
 double best=1e300,best_l[N]{};bool found=false;const unsigned limit=1u<<unsigned(n);
 for(unsigned mask=1;mask<limit;++mask){int ids[N],k=0;for(int i=0;i<n;++i)if(mask&(1u<<unsigned(i)))ids[k++]=i;double a[N+1][N+2]{};
  for(int r=0;r<k;++r){for(int q=0;q<k;++q)a[r][q]=phi[ids[r]][ids[q]];a[r][k]=1;a[r][k+1]=-rho[ids[r]];}for(int q=0;q<k;++q)a[k][q]=1;a[k][k+1]=double(L);
  bool ok=true;for(int col=0;col<=k;++col){int pivot=col;for(int r=col+1;r<=k;++r)if(absv(a[r][col])>absv(a[pivot][col]))pivot=r;if(absv(a[pivot][col])<1e-12){ok=false;break;}if(pivot!=col)for(int q=col;q<=k+1;++q){double t=a[col][q];a[col][q]=a[pivot][q];a[pivot][q]=t;}double div=a[col][col];for(int q=col;q<=k+1;++q)a[col][q]/=div;for(int r=0;r<=k;++r)if(r!=col){double f=a[r][col];for(int q=col;q<=k+1;++q)a[r][q]-=f*a[col][q];}}
  if(!ok)continue;double x[N]{},lambda=a[k][k+1],sum=0;for(int r=0;r<k;++r)x[ids[r]]=a[r][k+1];for(int i=0;i<n;++i){if(x[i]<-1e-8)ok=false;sum+=x[i];double g=rho[i]+lambda;for(int j=0;j<n;++j)g+=phi[i][j]*x[j];if(!(mask&(1u<<unsigned(i)))&&g<-1e-7)ok=false;}if(absv(sum-double(L))>1e-7)ok=false;if(!ok)continue;
  double obj=double(rd)*double(cl);for(int i=0;i<n;++i){obj+=rho[i]*x[i];for(int j=0;j<n;++j)obj+=0.5*x[i]*phi[i][j]*x[j];}if(!found||obj<best-1e-7){found=true;best=obj;for(int i=0;i<n;++i)best_l[i]=x[i];}
 }
 if(!found)return -1;std::int64_t fields[F]{};fields[0]=static_cast<std::int64_t>(best*1e6+0.5);for(int i=0;i<n;++i)fields[i+1]=static_cast<std::int64_t>((best_l[i]<0?0:best_l[i])*1e6+0.5);const std::size_t bytes=8*std::size_t(n+1);std::uint8_t stage[8*F]{};for(int i=0;i<n+1;++i)put(stage,8*std::size_t(i),fields[i]);if(!out||cap<bytes)return -2;for(std::size_t i=0;i<bytes;++i)out[i]=stage[i];return static_cast<std::int64_t>(bytes);
}
