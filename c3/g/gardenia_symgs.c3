// Clean-room bounded GARDENIA SymGS profile.
module gardenia_symgs;
extern fn double trunc(double value);
const long NMAX=8, MMAX=64, IMAX=173;
fn long gardenia_symgs(double* a,usz len,double* out,usz cap) @export("gardenia_symgs") {
    if(a==null||len<3||len>IMAX)return -1;
    for(usz q=0;q<len;q++)if(a[q]!=a[q]||a[q]>1.0e300||a[q]<-1.0e300)return -1;
    double nd=a[0],md=a[1],cd=a[2];if(trunc(nd)!=nd||trunc(md)!=md||trunc(cd)!=cd||nd<1||nd>NMAX||md<1||md>MMAX||cd<1||cd>nd)return -1;
    usz n=(usz)nd,m=(usz)md,c=(usz)cd;if(len!=5+4*n+c+2*m)return -1;
    usz oa=3,fa=oa+n,ra=fa+c+1,ca=ra+n+1,va=ca+m,xa=va+m,ba=xa+n;
    usz order[8]={0},offs[9]={0},row[9]={0},col[64]={0},group[8]={0};double mat[64]={0},x[8]={0},rhs[8]={0},staged[8]={0};bool seen[8]={false};
    for(usz i=0;i<n;i++){double z=a[oa+i];if(trunc(z)!=z||z<0||z>=nd||seen[(usz)z])return -1;order[i]=(usz)z;seen[order[i]]=true;}
    for(usz k=0;k<=c;k++){double z=a[fa+k];if(trunc(z)!=z||z<0||z>nd)return -1;offs[k]=(usz)z;}if(offs[0]!=0||offs[c]!=n)return -1;
    for(usz k=0;k<c;k++){if(offs[k]>=offs[k+1])return -1;for(usz p=offs[k];p<offs[k+1];p++)group[order[p]]=k;}
    for(usz i=0;i<=n;i++){double z=a[ra+i];if(trunc(z)!=z||z<0||z>md)return -1;row[i]=(usz)z;if(i>0&&row[i]<row[i-1])return -1;}if(row[0]!=0||row[n]!=m)return -1;
    for(usz u=0;u<n;u++){usz diag=0,prev=0;double d=0,offsum=0;for(usz e=row[u];e<row[u+1];e++){double z=a[ca+e];if(trunc(z)!=z||z<0||z>=nd)return -1;col[e]=(usz)z;if(e>row[u]&&col[e]<=prev)return -1;prev=col[e];mat[e]=a[va+e];if(mat[e]<-4||mat[e]>4)return -1;if(col[e]==u){diag++;d=mat[e];}else{if(group[u]==group[col[e]])return -1;offsum+=mat[e]<0?-mat[e]:mat[e];}}
        if(diag!=1||d<=offsum)return -1;for(usz e=row[u];e<row[u+1];e++){usz v=col[e];bool found=false;for(usz f=row[v];f<row[v+1];f++)if(col[f]==u){if(mat[f]!=mat[e])return -1;found=true;break;}if(!found)return -1;}}
    for(usz i=0;i<n;i++){x[i]=a[xa+i];rhs[i]=a[ba+i];if(x[i]<-4||x[i]>4||rhs[i]<-4||rhs[i]>4)return -1;}if(out==null||cap<n)return -2;
    for(usz pass=0;pass<2;pass++)for(usz step=0;step<c;step++){usz k=pass==0?step:c-1-step;for(usz p=offs[k];p<offs[k+1];p++){usz u=order[p];double sum=0,diag=0;for(usz e=row[u];e<row[u+1];e++){usz v=col[e];if(v==u)diag=mat[e];else sum+=x[v]*mat[e];}if(diag!=0)x[u]=(rhs[u]-sum)/diag;}}
    for(usz i=0;i<n;i++)staged[i]=x[i];for(usz i=0;i<n;i++)out[i]=staged[i];return (long)n;
}
