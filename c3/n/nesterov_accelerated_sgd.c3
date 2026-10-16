module nesterov_accelerated_sgd;
void put_double(char*out,usz off,double x){ulong bits=@bitcast(ulong,x);for(usz k=0;k<8;k++){out[off+k]=(char)(bits&255);bits>>=8;}}
fn long nesterov_accelerated_sgd(long*v,usz n,char*out,usz cap)@export("nesterov_accelerated_sgd"){
 if(v==null||n<4)return -1;long wi=v[0],si=v[1],lm=v[2],mm=v[3];if(wi<1||wi>8||si<1||si>8||lm<0||lm>1000||mm<0||mm>1000||n!=4+(usz)(wi*(si+1)))return -1;usz w=(usz)wi,s=(usz)si;for(usz i=4;i<n;i++)if(v[i]<-10000||v[i]>10000)return -1;if(out==null||cap<w*8)return -2;double p[8],vel[8]={0},lr=(double)lm/1000.0,m=(double)mm/1000.0;for(usz i=0;i<w;i++)p[i]=(double)v[4+i]/1000.0;for(usz t=0;t<s;t++)for(usz i=0;i<w;i++){double prev=vel[i],g=(double)v[4+w+t*w+i]/1000.0;vel[i]=m*vel[i]-lr*g;p[i]=p[i]-m*prev+(1.0+m)*vel[i];}for(usz i=0;i<w;i++)put_double(out,i*8,p[i]);return (long)(w*8);
}
