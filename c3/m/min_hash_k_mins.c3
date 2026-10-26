module min_hash_k_mins;
const usz MAX_N=16;const usz MAX_K=4;const usz MAX_INPUT=66;
fn void put64(char*o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}
long min_hash_k_mins(long*in,usz len,char*out,usz cap) @export("min_hash_k_mins"){
 if(in==null||len<3||len>MAX_INPUT)return -1;long nr=in[0],kr=in[1];if(nr<1||nr>16||kr<1||kr>4||len!=2+(usz)nr*(usz)kr)return -1;usz n=(usz)nr,k=(usz)kr;for(usz i=0;i<n*k;i+=1)if(in[2+i]<0||in[2+i]>1000)return -1;usz bytes=8*k;if(out==null||cap<bytes)return -2;for(usz col=0;col<k;col+=1){usz best=0;for(usz row=1;row<n;row+=1)if(in[2+row*k+col]<in[2+best*k+col])best=row;put64(out,8*col,(long)best);}return (long)bytes;
}
