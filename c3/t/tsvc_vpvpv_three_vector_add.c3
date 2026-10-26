// Clean-room implementation of TSVC vpvpv; see package rights note.
module tsvc_vpvpv_three_vector_add;
const int MAX_N = 32;
const usz MAX_INPUT_LENGTH = 98;
fn void store_i64_le(long value, char* out, usz pos) { ulong bits=(ulong)value; for(usz j=0;j<8;j++){out[pos+j]=(char)(bits&255);bits>>=8;} }
fn long tsvc_vpvpv_three_vector_add(long* input, usz length, char* output, usz capacity) @export("tsvc_vpvpv_three_vector_add") {
 if(input==null||length<5||length>MAX_INPUT_LENGTH)return -1;
 if(input[0]<1||input[0]>MAX_N||input[1]<1||input[1]>4||length!=2+3*input[0].usz())return -1;
 usz n=input[0].usz(),passes=input[1].usz();double a[MAX_N],b[MAX_N],c[MAX_N];
 for(usz i=0;i<n;i++){long av=input[2+i],bv=input[2+n+i],cv=input[2+2*n+i];if(av< -2||av>2||bv< -2||bv>2||cv< -2||cv>2)return -1;a[i]=(double)av;b[i]=(double)bv;c[i]=(double)cv;}
 usz bytes=8*n;if(output==null||capacity<bytes)return -2;
 for(usz p=0;p<passes;p++)for(usz i=0;i<n;i++)a[i]+=b[i]+c[i];
 for(usz i=0;i<n;i++)store_i64_le((long)a[i],output,8*i);return bytes.long();
}
