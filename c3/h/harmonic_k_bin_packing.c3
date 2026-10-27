module harmonic_k_bin_packing;
const usz MAX_N=32; const usz MAX_K=8; const usz MAX_INPUT=34; const long CAPACITY=10000;
fn void store_i64_le(char* out,usz off,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b+=1){out[off+b]=(char)(bits&255);bits>>=8;}}
long harmonic_k_bin_packing(long* input,usz length,char* output,usz capacity) @export("harmonic_k_bin_packing") {
 if(input==null||length<3||length>MAX_INPUT)return -1;
 long k64=input[0],n64=input[1];if(k64<3||k64>(long)MAX_K||n64<1||n64>(long)MAX_N||length!=2+(usz)n64)return -1;
 usz k=(usz)k64,n=(usz)n64;for(usz i=0;i<n;i+=1)if(input[2+i]<1||input[2+i]>CAPACITY)return -1;
 usz bytes=8*(n+1);if(output==null||capacity<bytes)return -2;
 long[MAX_K] current;long[MAX_K] remaining=zeroed;long[MAX_N] assignment=zeroed;
 for(usz c=0;c<MAX_K;c+=1)current[c]=-1;long bins=0;
 for(usz i=0;i<n;i+=1){long size=input[2+i];usz kind=k-1;
  for(usz c=0;c<k-1;c+=1)if(size*(long)(c+2)>CAPACITY){kind=c;break;}
  if(current[kind]<0||size>remaining[kind]){current[kind]=bins;bins+=1;remaining[kind]=CAPACITY;}
  assignment[i]=current[kind];remaining[kind]-=size;
 }
 store_i64_le(output,0,bins);for(usz i=0;i<n;i+=1)store_i64_le(output,8*(i+1),assignment[i]);return (long)bytes;
}
