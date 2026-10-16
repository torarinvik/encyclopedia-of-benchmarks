module dimensionality_reduction_lda;
extern fn double sqrt(double value);
fn long dimensionality_reduction_lda(double* v,usz n,double* out,usz cap) @export("dimensionality_reduction_lda") {
 if(v==null||n<16||v[0]!=2.0||v[2]!=2.0||v[3]!=1.0||v[1]<4.0||v[1]>8.0||v[1]!=(double)(long)v[1])return -1;usz m=(usz)v[1];usz base=4+2*m;double[8] x;double[8] y;double[2] mu0;double[2] mu1;usz c0=0;usz c1=0;mu0[0]=0;mu0[1]=0;mu1[0]=0;mu1[1]=0;
 for(usz i=0;i<m;i++){x[i]=v[4+i];y[i]=v[4+m+i];double label=v[base+i];if(x[i]!=x[i]||y[i]!=y[i]||x[i]<-10000||x[i]>10000||y[i]<-10000||y[i]>10000)return -1;if(label==0){c0++;mu0[0]+=x[i];mu0[1]+=y[i];}else if(label==1){c1++;mu1[0]+=x[i];mu1[1]+=y[i];}else { return -1; }}if(c0<2||c1<2)return -1;mu0[0]/=c0;mu0[1]/=c0;mu1[0]/=c1;mu1[1]/=c1;
 double a=0;double b=0;double d=0;for(usz i=0;i<m;i++){double dx=x[i]-(v[base+i]==0?mu0[0]:mu1[0]);double dy=y[i]-(v[base+i]==0?mu0[1]:mu1[1]);a+=dx*dx;b+=dx*dy;d+=dy*dy;}a/=m;b/=m;d/=m;double det=a*d-b*b;if(det<=1e-12)return -1;double dx=mu1[0]-mu0[0];double dy=mu1[1]-mu0[1];double w0=(d*dx-b*dy)/det;double w1=(a*dy-b*dx)/det;double norm=sqrt(w0*w0+w1*w1);if(norm<=1e-12)return -1;w0/=norm;w1/=norm;if(w0<0||(w0<1e-14&&w1<0)){w0=-w0;w1=-w1;}if(out==null||cap<m)return -2;for(usz i=0;i<m;i++)out[i]=w0*x[i]+w1*y[i];return (long)m;
}
