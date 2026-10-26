/* Clean-room bounded sequential GARDENIA MF-SGD profile. */
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t gardenia_sgd(const double* a,std::size_t len,double* out,std::size_t cap) noexcept{
    constexpr std::size_t N=8,M=24,K=4,IMAX=92;
    if(!a||len<4||len>IMAX)return -1;for(std::size_t q=0;q<len;++q)if(!std::isfinite(a[q]))return -1;
    double uv=a[0],iv=a[1],mv=a[2],kv=a[3];if(std::trunc(uv)!=uv||std::trunc(iv)!=iv||std::trunc(mv)!=mv||std::trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<1||mv>M||kv<1||kv>K)return -1;
    auto users=std::size_t(uv),items=std::size_t(iv),m=std::size_t(mv),k=std::size_t(kv),n=users+items;if(n>N||len!=5+users+2*m+n*k)return -1;
    auto rp=std::size_t(4),ci=rp+users+1,ra=ci+m,la=ra+m;std::size_t row[N+1]{},col[M]{};double rating[M]{},latent[N*K]{},errors[N]{},staged[N*K]{};
    for(std::size_t i=0;i<=users;++i){double z=a[rp+i];if(std::trunc(z)!=z||z<0||z>m)return -1;row[i]=std::size_t(z);if(i&&row[i]<row[i-1])return -1;}if(row[0]!=0||row[users]!=m)return -1;
    for(std::size_t e=0;e<m;++e){double z=a[ci+e];if(std::trunc(z)!=z||z<0||z>=items)return -1;col[e]=std::size_t(z);rating[e]=a[ra+e];if(rating[e] < -4||rating[e]>4)return -1;}
    for(std::size_t q=0;q<n*k;++q){latent[q]=a[la+q];if(latent[q]<0||latent[q]>0.1)return -1;}auto required=n*k;if(!out||cap<required)return -2;
    for(std::size_t iter=0;iter<3;++iter){for(std::size_t u=0;u<users;++u)errors[u]=0;for(std::size_t u=0;u<users;++u)for(auto e=row[u];e<row[u+1];++e){auto v=users+col[e];double estimate=0;for(std::size_t f=0;f<k;++f)estimate+=latent[u*k+f]*latent[v*k+f];double delta=rating[e]-estimate;errors[u]+=delta*delta;for(std::size_t f=0;f<k;++f){auto ui=u*k+f,vi=v*k+f;double pu=latent[ui],pi=latent[vi];latent[ui]+=0.00000035*(-0.001*pu+pi*delta);latent[vi]+=0.00000035*(-0.001*pi+pu*delta);}}double total=0;for(std::size_t u=0;u<users;++u)total+=errors[u];if(std::sqrt(total/double(m))<0.1)break;}
    for(std::size_t q=0;q<required;++q)staged[q]=latent[q];for(std::size_t q=0;q<required;++q)out[q]=staged[q];return std::int64_t(required);
}
