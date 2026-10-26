module three_dimensional_moment_curve;
const int MAX_N=64;const int MAX_OUTPUT=1544;
fn void put_i64(char* out,usz offset,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[offset+i]=(char)(bits&255);bits>>=8;}}
fn long three_dimensional_moment_curve(long* v,usz length,char* output,usz capacity) @export("three_dimensional_moment_curve") {
 if(v==null||length!=1||v[0]<0||v[0]>MAX_N)return -1;int n=(int)v[0];usz bytes=8*(1+3*n);if(output==null||capacity<bytes)return -2;
 char[MAX_OUTPUT] staged={};put_i64(staged,0,n);for(int i=1;i<=n;i++){long x=i;usz offset=8*(1+3*(i-1));put_i64(staged,offset,x);put_i64(staged,offset+8,x*x);put_i64(staged,offset+16,x*x*x);}for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
