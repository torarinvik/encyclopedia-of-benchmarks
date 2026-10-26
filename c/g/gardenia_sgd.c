/* Clean-room bounded sequential GARDENIA MF-SGD profile. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define NMAX 8
#define MMAX 24
#define KMAX 4
#define IMAX 92
int64_t gardenia_sgd(const double *a,size_t len,double *out,size_t cap){
    if(!a||len<4||len>IMAX)return -1;for(size_t q=0;q<len;++q)if(!isfinite(a[q]))return -1;
    double uv=a[0],iv=a[1],mv=a[2],kv=a[3];if(trunc(uv)!=uv||trunc(iv)!=iv||trunc(mv)!=mv||trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<1||mv>MMAX||kv<1||kv>KMAX)return -1;
    size_t users=(size_t)uv,items=(size_t)iv,m=(size_t)mv,k=(size_t)kv,n=users+items;if(n>NMAX||len!=5+users+2*m+n*k)return -1;
    size_t rp=4,ci=rp+users+1,ra=ci+m,la=ra+m;size_t row[NMAX+1]={0},col[MMAX]={0};double rating[MMAX]={0},latent[NMAX*KMAX]={0},errors[NMAX]={0},staged[NMAX*KMAX]={0};
    for(size_t i=0;i<=users;++i){double z=a[rp+i];if(trunc(z)!=z||z<0||z>m)return -1;row[i]=(size_t)z;if(i&&row[i]<row[i-1])return -1;}
    if(row[0]!=0||row[users]!=m)return -1;
    for(size_t e=0;e<m;++e){double z=a[ci+e];if(trunc(z)!=z||z<0||z>=items)return -1;col[e]=(size_t)z;rating[e]=a[ra+e];if(rating[e] < -4||rating[e]>4)return -1;}
    for(size_t q=0;q<n*k;++q){latent[q]=a[la+q];if(latent[q]<0||latent[q]>0.1)return -1;}
    size_t required=n*k;if(!out||cap<required)return -2;
    for(size_t iter=0;iter<3;++iter){for(size_t u=0;u<users;++u)errors[u]=0;
        for(size_t u=0;u<users;++u)for(size_t e=row[u];e<row[u+1];++e){size_t v=users+col[e];double estimate=0;for(size_t f=0;f<k;++f)estimate+=latent[u*k+f]*latent[v*k+f];double delta=rating[e]-estimate;errors[u]+=delta*delta;for(size_t f=0;f<k;++f){size_t ui=u*k+f,vi=v*k+f;double pu=latent[ui],pi=latent[vi];latent[ui]+=0.00000035*(-0.001*pu+pi*delta);latent[vi]+=0.00000035*(-0.001*pi+pu*delta);}}
        double total=0;for(size_t u=0;u<users;++u)total+=errors[u];if(sqrt(total/(double)m)<0.1)break;
    }
    for(size_t q=0;q<required;++q)staged[q]=latent[q];for(size_t q=0;q<required;++q)out[q]=staged[q];return (int64_t)required;
}
