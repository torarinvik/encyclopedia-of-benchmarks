module ams_sketch;
fn void put_i64_le(char*out,long x){ulong u=(ulong)x;for(usz b=0;b<8;b++){out[b]=(char)(u&255);u>>=8;}}
fn long ams_sketch(long*in,usz len,char*out,usz cap) @export("ams_sketch"){
 if(in==null||len<4||len>116)return -1;long d0=in[0],w0=in[1],k0=in[2],u0=in[3];if((d0!=1&&d0!=3&&d0!=5)||w0<1||w0>8||k0<1||k0>8||u0<0||u0>16)return -1;
 usz d=(usz)d0,w=(usz)w0,k=(usz)k0,u=(usz)u0,start=4+2*d*k;if(len!=start+2*u)return -1;
 for(usz r=0;r<d;r++)for(usz key=0;key<k;key++){usz p=4+2*(r*k+key);if(in[p]<0||in[p]>=w0||(in[p+1]!=-1&&in[p+1]!=1))return -1;}
 for(usz i=0;i<u;i++){long key=in[start+2*i],weight=in[start+2*i+1];if(key<0||key>=k0||weight< -1000||weight>1000)return -1;}
 long[5][8] counters=zeroed;long[5] estimates=zeroed;
 for(usz i=0;i<u;i++){usz key=(usz)in[start+2*i];long weight=in[start+2*i+1];for(usz r=0;r<d;r++){usz p=4+2*(r*k+key),b=(usz)in[p];counters[r][b]+=weight*in[p+1];}}
 for(usz r=0;r<d;r++)for(usz b=0;b<w;b++)estimates[r]+=counters[r][b]*counters[r][b];
 for(usz i=1;i<d;i++){long x=estimates[i];usz j=i;while(j>0&&estimates[j-1]>x){estimates[j]=estimates[j-1];j--;}estimates[j]=x;}
 if(cap<8||out==null)return -2;put_i64_le(out,estimates[d/2]);return 8;
}
