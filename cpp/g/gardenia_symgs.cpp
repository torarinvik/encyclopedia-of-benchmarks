/* Clean-room bounded GARDENIA SymGS profile. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t gardenia_symgs(const double* a,std::size_t len,double* out,std::size_t cap) noexcept{
    constexpr std::size_t N=8,M=64,IMAX=5+5*N+2*M;
    if(!a||len<3||len>IMAX)return -1;for(std::size_t q=0;q<len;++q)if(!std::isfinite(a[q]))return -1;
    double nd=a[0],md=a[1],cd=a[2];if(std::trunc(nd)!=nd||std::trunc(md)!=md||std::trunc(cd)!=cd||nd<1||nd>N||md<1||md>M||cd<1||cd>nd)return -1;
    auto n=std::size_t(nd),m=std::size_t(md),c=std::size_t(cd);if(len!=5+4*n+c+2*m)return -1;
    auto oa=std::size_t(3),fa=oa+n,ra=fa+c+1,ca=ra+n+1,va=ca+m,xa=va+m,ba=xa+n;
    std::size_t order[N]{},offs[N+1]{},row[N+1]{},col[M]{},group[N]{};double mat[M]{},x[N]{},rhs[N]{},staged[N]{};bool seen[N]{};
    for(std::size_t i=0;i<n;++i){double z=a[oa+i];if(std::trunc(z)!=z||z<0||z>=nd||seen[std::size_t(z)])return -1;order[i]=std::size_t(z);seen[order[i]]=true;}
    for(std::size_t k=0;k<=c;++k){double z=a[fa+k];if(std::trunc(z)!=z||z<0||z>nd)return -1;offs[k]=std::size_t(z);}if(offs[0]!=0||offs[c]!=n)return -1;for(std::size_t k=0;k<c;++k)if(offs[k]>=offs[k+1])return -1;
    for(std::size_t k=0;k<c;++k)for(std::size_t p=offs[k];p<offs[k+1];++p)group[order[p]]=k;
    for(std::size_t i=0;i<=n;++i){double z=a[ra+i];if(std::trunc(z)!=z||z<0||z>md)return -1;row[i]=std::size_t(z);if(i&&row[i]<row[i-1])return -1;}if(row[0]!=0||row[n]!=m)return -1;
    for(std::size_t u=0;u<n;++u){std::size_t diag=0,prev=0;double d=0,offsum=0;for(std::size_t e=row[u];e<row[u+1];++e){double z=a[ca+e];if(std::trunc(z)!=z||z<0||z>=nd)return -1;col[e]=std::size_t(z);if(e>row[u]&&col[e]<=prev)return -1;prev=col[e];mat[e]=a[va+e];if(mat[e]<-4||mat[e]>4)return -1;if(col[e]==u){++diag;d=mat[e];}else{offsum+=std::fabs(mat[e]);if(group[u]==group[col[e]])return -1;}}
        if(diag!=1||d<=offsum)return -1;for(std::size_t e=row[u];e<row[u+1];++e){auto v=col[e];bool found=false;for(std::size_t f=row[v];f<row[v+1];++f)if(col[f]==u){if(mat[f]!=mat[e])return -1;found=true;break;}if(!found)return -1;}}
    for(std::size_t i=0;i<n;++i){x[i]=a[xa+i];rhs[i]=a[ba+i];if(x[i]<-4||x[i]>4||rhs[i]<-4||rhs[i]>4)return -1;}if(!out||cap<n)return -2;
    for(std::size_t pass=0;pass<2;++pass)for(std::size_t step=0;step<c;++step){auto k=pass==0?step:c-1-step;for(std::size_t p=offs[k];p<offs[k+1];++p){auto u=order[p];double sum=0,diag=0;for(std::size_t e=row[u];e<row[u+1];++e){auto v=col[e];if(v==u)diag=mat[e];else sum+=x[v]*mat[e];}if(diag!=0)x[u]=(rhs[u]-sum)/diag;}}
    for(std::size_t i=0;i<n;++i)staged[i]=x[i];for(std::size_t i=0;i<n;++i)out[i]=staged[i];return std::int64_t(n);
}
