module fresnel_diffract;
fn long fresnel_diffract(double* v,usz n,double* out,usz cap) @export("fresnel_diffract") {
 if(v==null||n!=12||v[0]!=4||v[1]!=1||v[2]!=1||v[3]!=16)return -1;for(usz i=4;i<12;i++)if(v[i]!=v[i]||v[i]<-100||v[i]>100)return -1;if(out==null||cap<8)return -2;
 double[4] xr={v[6],v[7],v[4],v[5]};double[4] xi={v[10],v[11],v[8],v[9]};double[4] cr={1,0,-1,0};double[4] si={0,-1,0,1};double[4] fr={0,0,0,0};double[4] fi={0,0,0,0};
 for(usz k=0;k<4;k++)for(usz j=0;j<4;j++){usz t=(k*j)&3;fr[k]+=xr[j]*cr[t]-xi[j]*si[t];fi[k]+=xr[j]*si[t]+xi[j]*cr[t];}
 for(usz k=1;k<4;k+=2){fr[k]=-fr[k];fi[k]=-fi[k];}
 double[4] zr={0,0,0,0};double[4] zi={0,0,0,0};for(usz j=0;j<4;j++)for(usz k=0;k<4;k++){usz t=(k*j)&3;double s=-si[t];zr[j]+=(fr[k]*cr[t]-fi[k]*s)*0.25;zi[j]+=(fr[k]*s+fi[k]*cr[t])*0.25;}
 out[0]=zr[2];out[1]=zr[3];out[2]=zr[0];out[3]=zr[1];out[4]=zi[2];out[5]=zi[3];out[6]=zi[0];out[7]=zi[1];return 8;
}
