module extended_kalman_filter;
const double BAD=-1.0e300;
fn double extended_kalman_filter(long* v, usz n) @export("extended_kalman_filter") {
 if(v==null||n<10||n>17)return BAD;long steps=v[0];if(steps<1||steps>8||n!=(usz)(9+steps))return BAD;
 for(usz i=1;i<9;i++)if(v[i]<-10000||v[i]>10000)return BAD;for(usz i=9;i<n;i++)if(v[i]<-10000||v[i]>10000)return BAD;
 double sc=1000.0;double x=(double)v[1]/sc;double y=(double)v[2]/sc;double p00=(double)v[3]/sc;double p01=(double)v[4]/sc;double p11=(double)v[5]/sc;double q0=(double)v[6]/sc;double q1=(double)v[7]/sc;double r=(double)v[8]/sc;
 if(v[1]<-2000||v[1]>2000||v[2]<-2000||v[2]>2000||p00<=0||p11<=0||p00*p11<=p01*p01||q0<0||q1<0||r<=0||r>10)return BAD;
 for (long t = 0; t < steps; t++){double f01=0.1;double f10=0.1*x;double nx=x+f01*y;double ny=y+0.05*x*x;double a=p00+2*f01*p01+f01*f01*p11+q0;double b=f10*p00+(1+f01*f10)*p01+f01*p11;double c=f10*f10*p00+2*f10*p01+p11+q1;x=nx;y=ny;p00=a;p01=b;p11=c;
 double h0=0.1*x;double res=(double)v[9+(usz)t]/sc-(0.05*x*x+y);double s=h0*h0*p00+2*h0*p01+p11+r;if(s<=0)return BAD;double k0=(p00*h0+p01)/s;double k1=(p01*h0+p11)/s;x+=k0*res;y+=k1*res;
 double a00=1-k0*h0;double a01=-k0;double a10=-k1*h0;double a11=1-k1;double z00=a00*a00*p00+2*a00*a01*p01+a01*a01*p11+k0*k0*r;double z01=a00*a10*p00+(a00*a11+a01*a10)*p01+a01*a11*p11+k0*k1*r;double z11=a10*a10*p00+2*a10*a11*p01+a11*a11*p11+k1*k1*r;p00=z00;p01=z01;p11=z11;}
 return x;
}
