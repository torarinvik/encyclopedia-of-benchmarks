// Clean-room TSVC s1111 profile; see package rights note.
module tsvc_s1111_stride_two_polynomial_map;
const usz MAX_N=32;const usz MAX_INPUT_LENGTH=161;
fn void put64(char* out,long v){ulong bits=(ulong)v;for(usz j=0;j<8;j++){out[j]=(char)(bits&255);bits>>=8;}}
fn long tsvc_s1111_stride_two_polynomial_map(long* in,usz len,char* out,usz cap) @export("tsvc_s1111_stride_two_polynomial_map") {
 if(in==null||len<6||len>MAX_INPUT_LENGTH)return -1;long nr=in[0];if(nr<1||nr>(long)MAX_N)return -1;usz n=(usz)nr;if(len!=1+5*n)return -1;
 long[64] a;long[32] b;long[32] c;long[32] d;usz off=1;
 for(usz i=0;i<2*n;i++){long x=in[off+i];if(x< -2||x>2)return -1;a[i]=x;}off+=2*n;
 for(usz i=0;i<n;i++){long x=in[off+i];if(x< -2||x>2)return -1;b[i]=x;}off+=n;
 for(usz i=0;i<n;i++){long x=in[off+i];if(x< -2||x>2)return -1;c[i]=x;}off+=n;
 for(usz i=0;i<n;i++){long x=in[off+i];if(x< -2||x>2)return -1;d[i]=x;}
 usz bytes=16*n;if(out==null||cap<bytes)return -2;for(usz i=0;i<n;i++)a[2*i]=c[i]*b[i]+d[i]*b[i]+c[i]*c[i]+d[i]*b[i]+d[i]*c[i];for(usz i=0;i<2*n;i++)put64(out+8*i,a[i]);return (long)(2*n);
}
