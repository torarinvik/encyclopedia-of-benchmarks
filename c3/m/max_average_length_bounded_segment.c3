module max_average_length_bounded_segment;
const usz MAX_N=32;const usz MAX_INPUT=35;
fn void put64(char*o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}
long max_average_length_bounded_segment(long*in,usz len,char*out,usz cap) @export("max_average_length_bounded_segment"){
 if(in==null||len<4||len>MAX_INPUT)return -1;long n64=in[0],l64=in[1],u64=in[2];if(n64<1||n64>(long)MAX_N||l64<1||u64<l64||u64>n64||len!=3+(usz)n64)return -1;usz n=(usz)n64,l=(usz)l64,u=(usz)u64;
 for(usz i=0;i<n;i+=1)if(in[3+i]<-10000||in[3+i]>10000)return -1;if(out==null||cap<32)return -2;
 long bs=0,bl=1,bstart=0,bend=0;bool have=false;
 for(usz start=0;start<n;start+=1){long sum=0;usz limit=start+u<n?start+u:n;for(usz end=start+1;end<=limit;end+=1){sum+=in[3+end-1];usz length=end-start;if(length<l)continue;long left=sum*bl,right=bs*(long)length;
  if(!have||left>right||(left==right&&(length<(usz)bl||(length==(usz)bl&&(start<(usz)bstart||(start==(usz)bstart&&end<(usz)bend)))))){bs=sum;bl=(long)length;bstart=(long)start;bend=(long)end;have=true;}
 }}put64(out,0,bs);put64(out,8,bl);put64(out,16,bstart);put64(out,24,bend);return 32;
}
