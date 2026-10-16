#include <stddef.h>
#include <stdint.h>

int64_t fresnel_diffract(const double *v,size_t n,double *out,size_t cap){
 if(!v||n!=12||v[0]!=4||v[1]!=1||v[2]!=1||v[3]!=16)return -1;
 for(size_t i=4;i<12;i++)if(v[i]!=v[i]||v[i]<-100||v[i]>100)return -1;
 if(!out||cap<8)return -2;
 double xr[4]={v[6],v[7],v[4],v[5]},xi[4]={v[10],v[11],v[8],v[9]};
 const double cr[4]={1,0,-1,0},si[4]={0,-1,0,1};
 double fr[4]={0},fi[4]={0};
 for(int k=0;k<4;k++)for(int j=0;j<4;j++){int t=(k*j)&3;fr[k]+=xr[j]*cr[t]-xi[j]*si[t];fi[k]+=xr[j]*si[t]+xi[j]*cr[t];}
 for(int k=1;k<4;k+=2){fr[k]=-fr[k];fi[k]=-fi[k];}
 double zr[4]={0},zi[4]={0};
 for(int j=0;j<4;j++)for(int k=0;k<4;k++){int t=(k*j)&3;double s=-si[t];zr[j]+=(fr[k]*cr[t]-fi[k]*s)*0.25;zi[j]+=(fr[k]*s+fi[k]*cr[t])*0.25;}
 out[0]=zr[2];out[1]=zr[3];out[2]=zr[0];out[3]=zr[1];out[4]=zi[2];out[5]=zi[3];out[6]=zi[0];out[7]=zi[1];return 8;
}
