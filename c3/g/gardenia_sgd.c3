// Clean-room bounded sequential GARDENIA MF-SGD profile.
module gardenia_sgd;
extern fn double trunc(double value);
extern fn double sqrt(double value);
const long IMAX=92;
fn long gardenia_sgd(double* a,usz len,double* out,usz cap) @export("gardenia_sgd") {
    if(a==null||len<4||len>IMAX)return -1;
    for(usz q=0;q<len;q++)if(a[q]!=a[q]||a[q]>1.0e300||a[q] < -1.0e300)return -1;
    double uv=a[0],iv=a[1],mv=a[2],kv=a[3];if(trunc(uv)!=uv||trunc(iv)!=iv||trunc(mv)!=mv||trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<1||mv>24||kv<1||kv>4)return -1;
    usz users=(usz)uv,items=(usz)iv,m=(usz)mv,k=(usz)kv,n=users+items;if(n>8||len!=5+users+2*m+n*k)return -1;
    usz rp=4,ci=rp+users+1,ra=ci+m,la=ra+m;usz row[9]={0},col[24]={0};double rating[24]={0},latent[32]={0},errors[8]={0},staged[32]={0};
    for(usz i=0;i<=users;i++){double z=a[rp+i];if(trunc(z)!=z||z<0||z>(double)m)return -1;row[i]=(usz)z;if(i>0&&row[i]<row[i-1])return -1;}if(row[0]!=0||row[users]!=m)return -1;
    for(usz e=0;e<m;e++){double z=a[ci+e];if(trunc(z)!=z||z<0||z>=iv)return -1;col[e]=(usz)z;rating[e]=a[ra+e];if(rating[e] < -4||rating[e]>4)return -1;}
    for(usz q=0;q<n*k;q++){latent[q]=a[la+q];if(latent[q]<0||latent[q]>0.1)return -1;}usz required=n*k;if(out==null||cap<required)return -2;
    for(usz iter=0;iter<3;iter++){for(usz u=0;u<users;u++)errors[u]=0;for(usz u=0;u<users;u++)for(usz e=row[u];e<row[u+1];e++){usz v=users+col[e];double estimate=0;for(usz f=0;f<k;f++)estimate+=latent[u*k+f]*latent[v*k+f];double delta=rating[e]-estimate;errors[u]+=delta*delta;for(usz f=0;f<k;f++){usz ui=u*k+f,vi=v*k+f;double pu=latent[ui],pi=latent[vi];latent[ui]+=0.00000035*(-0.001*pu+pi*delta);latent[vi]+=0.00000035*(-0.001*pi+pu*delta);}}
        double total=0;for(usz u=0;u<users;u++)total+=errors[u];if(sqrt(total/(double)m)<0.1)break;}
    for(usz q=0;q<required;q++)staged[q]=latent[q];for(usz q=0;q<required;q++)out[q]=staged[q];return (long)required;
}
