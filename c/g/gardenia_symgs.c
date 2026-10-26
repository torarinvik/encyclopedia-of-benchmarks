/* Clean-room bounded GARDENIA SymGS profile. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define NMAX 8
#define MMAX 64
#define IMAX (5+5*NMAX+2*MMAX)
int64_t gardenia_symgs(const double *a,size_t len,double *out,size_t cap){
    if(!a||len<3||len>IMAX)return -1;for(size_t q=0;q<len;++q)if(!isfinite(a[q]))return -1;
    double nd=a[0],md=a[1],cd=a[2];if(trunc(nd)!=nd||trunc(md)!=md||trunc(cd)!=cd||nd<1||nd>NMAX||md<1||md>MMAX||cd<1||cd>nd)return -1;
    size_t n=(size_t)nd,m=(size_t)md,c=(size_t)cd;if(len!=5+4*n+c+2*m)return -1;
    size_t oa=3,fa=oa+n,ra=fa+c+1,ca=ra+n+1,va=ca+m,xa=va+m,ba=xa+n;
    size_t order[NMAX],offs[NMAX+1],row[NMAX+1],col[MMAX],group[NMAX];double mat[MMAX],x[NMAX],rhs[NMAX],staged[NMAX];
    unsigned char seen[NMAX]={0};
    for(size_t i=0;i<n;++i){double z=a[oa+i];if(trunc(z)!=z||z<0||z>=nd||seen[(size_t)z])return -1;order[i]=(size_t)z;seen[order[i]]=1;}
    for(size_t k=0;k<=c;++k){double z=a[fa+k];if(trunc(z)!=z||z<0||z>nd)return -1;offs[k]=(size_t)z;}
    if(offs[0]!=0||offs[c]!=n)return -1;for(size_t k=0;k<c;++k)if(offs[k]>=offs[k+1])return -1;
    for(size_t k=0;k<c;++k)for(size_t p=offs[k];p<offs[k+1];++p)group[order[p]]=k;
    for(size_t i=0;i<=n;++i){double z=a[ra+i];if(trunc(z)!=z||z<0||z>md)return -1;row[i]=(size_t)z;if(i&&row[i]<row[i-1])return -1;}
    if(row[0]!=0||row[n]!=m)return -1;
    for(size_t u=0;u<n;++u){size_t diag=0;double d=0.0,offsum=0.0;size_t prev=0;
        for(size_t e=row[u];e<row[u+1];++e){double z=a[ca+e];if(trunc(z)!=z||z<0||z>=nd)return -1;col[e]=(size_t)z;if(e>row[u]&&col[e]<=prev)return -1;prev=col[e];mat[e]=a[va+e];if(mat[e]<-4||mat[e]>4)return -1;if(col[e]==u){++diag;d=mat[e];}else{offsum+=fabs(mat[e]);if(group[u]==group[col[e]])return -1;}}
        if(diag!=1||d<=offsum)return -1;
        for(size_t e=row[u];e<row[u+1];++e){size_t v=col[e];int found=0;for(size_t f=row[v];f<row[v+1];++f)if(col[f]==u){if(mat[f]!=mat[e])return -1;found=1;break;}if(!found)return -1;}
    }
    for(size_t i=0;i<n;++i){x[i]=a[xa+i];rhs[i]=a[ba+i];if(x[i]<-4||x[i]>4||rhs[i]<-4||rhs[i]>4)return -1;}
    if(!out||cap<n)return -2;
    for(size_t pass=0;pass<2;++pass){for(size_t step=0;step<c;++step){size_t k=pass==0?step:c-1-step;for(size_t p=offs[k];p<offs[k+1];++p){size_t u=order[p];double sum=0.0,diag=0.0;for(size_t e=row[u];e<row[u+1];++e){size_t v=col[e];if(v==u)diag=mat[e];else sum+=x[v]*mat[e];}if(diag!=0.0)x[u]=(rhs[u]-sum)/diag;}}}
    for(size_t i=0;i<n;++i)staged[i]=x[i];for(size_t i=0;i<n;++i)out[i]=staged[i];return (int64_t)n;
}
