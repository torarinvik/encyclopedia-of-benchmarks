// Clean-room TSVC s471 profile; see package rights note.
module tsvc_s471_ordered_two_vector_map;
const int MAX_N=32; const usz MAX_INPUT_LENGTH=130;
fn void put64(long v,char* o,usz p){ulong b=(ulong)v;for(usz j=0;j<8;j++){o[p+j]=(char)(b&255);b>>=8;}}
fn long tsvc_s471_ordered_two_vector_map(long* in,usz len,char* out,usz cap) @export("tsvc_s471_ordered_two_vector_map") {
 if(in==null||len<6||len>MAX_INPUT_LENGTH)return -1;
 if(in[0]<1||in[0]>MAX_N||in[1]<1||in[1]>4||len!=2+4*in[0].usz())return -1;
 usz n=in[0].usz(),passes=in[1].usz();double x[MAX_N],b[MAX_N],c[MAX_N],d[MAX_N],e[MAX_N];
 for(usz i=0;i<n;i++){long bv=in[2+i],cv=in[2+n+i],dv=in[2+2*n+i],ev=in[2+3*n+i];if(bv< -2||bv>2||cv< -2||cv>2||dv< -2||dv>2||ev< -2||ev>2)return -1;b[i]=(double)bv;c[i]=(double)cv;d[i]=(double)dv;e[i]=(double)ev;}
 usz bytes=16*n;if(out==null||cap<bytes)return -2;
 for(usz p=0;p<passes;p++)for(usz i=0;i<n;i++){x[i]=b[i]+d[i]*d[i];b[i]=c[i]+d[i]*e[i];}
 for(usz i=0;i<n;i++){put64((long)x[i],out,8*i);put64((long)b[i],out,8*(n+i));}return bytes.long();
}
