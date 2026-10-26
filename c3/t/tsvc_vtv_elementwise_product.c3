// Clean-room implementation of TSVC vtv; see package rights note.
module tsvc_vtv_elementwise_product;
const int MAX_N = 32;
const usz MAX_INPUT_LENGTH = 66;
fn void store_i64_le(long value, char* out, usz pos) { ulong bits=(ulong)value; for(usz j=0;j<8;j++){out[pos+j]=(char)(bits&255);bits>>=8;} }
fn long tsvc_vtv_elementwise_product(long* input, usz length, char* output, usz capacity) @export("tsvc_vtv_elementwise_product") {
 if(input==null||length<4||length>MAX_INPUT_LENGTH)return -1;
 if(input[0]<1||input[0]>MAX_N||input[1]<1||input[1]>8||length!=2+2*input[0].usz())return -1;
 usz n=input[0].usz(),passes=input[1].usz();double a[MAX_N],b[MAX_N];
 for(usz i=0;i<n;i++){long av=input[2+i],bv=input[2+n+i];if(av< -2||av>2||bv< -2||bv>2)return -1;a[i]=(double)av;b[i]=(double)bv;}
 usz bytes=8*n;if(output==null||capacity<bytes)return -2;
 for(usz p=0;p<passes;p++)for(usz i=0;i<n;i++)a[i]*=b[i];
 for(usz i=0;i<n;i++)store_i64_le((long)a[i],output,8*i);return bytes.long();
}
