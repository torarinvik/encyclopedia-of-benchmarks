module neural_network;
import "math";
void putd(char *o,usz p,double x){ulong b=@bitcast(ulong,x);for(usz k=0;k<8;k++){o[p+k]=(char)(b&255);b>>=8;}}
double sig(double x){return 1.0/(1.0+math.exp(-x));}
fn long neural_network(long *v,usz n,char *o,usz cap) @export("neural_network"){if(v==null||n<7)return -1;int ni=(int)v[0],nh=(int)v[1],no=(int)v[2];if(ni<1||ni>3||nh<1||nh>3||no<1||no>3||n!=3+(usz)ni+(usz)ni*(usz)nh+(usz)nh*(usz)no)return -1;for(usz i=3;i<n;i++)if(v[i] < -1000||v[i]>1000)return -1;if(o==null||cap<(usz)no*8)return -2;usz xs=3,w1=xs+(usz)ni,w2=w1+(usz)ni*(usz)nh;double h[3]={0};for(int j=0;j<nh;j++){double z=0;for(int i=0;i<ni;i++)z+=(double)v[xs+(usz)i]/1000.0*((double)v[w1+(usz)i*(usz)nh+(usz)j]/1000.0);h[j]=sig(z);}for(int j=0;j<no;j++){double z=0;for(int i=0;i<nh;i++)z+=h[i]*((double)v[w2+(usz)i*(usz)no+(usz)j]/1000.0);putd(o,(usz)j*8,sig(z));}return (long)no*8;}
