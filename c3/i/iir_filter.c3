module iir_filter;
fn void put64(char *o,usz s,double x){ulong b=@bitcast(ulong,x);for(usz k=0;k<8;k++){o[s*8+k]=(char)(b&255);b>>=8;}}
fn long iir_filter(long *v,usz n,char *out,usz cap) @export("iir_filter"){
 if(v==null||n<7||n>26||v[0]<1||v[0]>3||v[1]<1||v[1]>16)return -1;usz order=(usz)v[0],samples=(usz)v[1];if(n!=4+2*order+samples)return -1;
 double[4] a;double[4] b;double[3] xh;double[3] yh;for(usz i=0;i<4;i++){a[i]=0.0;b[i]=0.0;}for(usz i=0;i<3;i++){xh[i]=0.0;yh[i]=0.0;}
 for(usz i=0;i<=order;i++){long av=v[2+i],bv=v[3+order+i];if(av < -500||av>2000||bv < -500||bv>500)return -1;a[i]=(double)av/1000.0;b[i]=(double)bv/1000.0;}if(a[0]<0.5)return -1;for(usz i=0;i<samples;i++)if(v[4+2*order+i]<-1000||v[4+2*order+i]>1000)return -1;
 usz bytes=samples*8;if(out==null||cap<bytes)return -2;for(usz s=0;s<samples;s++){double x=(double)v[4+2*order+s]/1000.0;double y=0.0;for(usz i=1;i<=order;i++)y+=b[i]*xh[i-1]-a[i]*yh[i-1];y=(y+b[0]*x)/a[0];usz i=order;while(i>1){i--;xh[i]=xh[i-1];yh[i]=yh[i-1];}xh[0]=x;yh[0]=y;put64(out,s,y);}return (long)bytes;
}
