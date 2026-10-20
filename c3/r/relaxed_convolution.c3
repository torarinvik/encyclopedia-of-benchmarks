module relaxed_convolution;
// New bounded relaxed-convolution schedule; see benchmarks/r/relaxed_convolution/README.md and LICENSE.txt.
const long MOD=998244353;
fn long relaxed_convolution(long* input,usz length,uint8* output,usz capacity) @export("relaxed_convolution") {
    if(input==null||length<3||length>33)return -1;long n0=input[0];if(n0<1||n0>16||length!=1+2*(usz)n0)return -1;
    int n=(int)n0;long[16] a,b,c;
    for(int i=0;i<n;i++){a[i]=input[1+i];b[i]=input[1+n+i];if(a[i]<0||a[i]>=MOD||b[i]<0||b[i]>=MOD)return -1;}
    if(output==null||capacity<4*n)return -2;
    for(int index=0;index<n;index++){
        c[index]=(c[index]+a[index]*b[0]+(index!=0?b[index]*a[0]:0))%MOD;int q=index+1;
        for(int d=1;d<=q;d*=2){if(q%(2*d)!=d)continue;int end=q+d<n?q+d:n;
            if(q==d){for(int i=q;i<end;i++){int target=d+i-q;for(int r=0;r<d;r++){int y=target-r;if(y<d)c[i]=(c[i]+a[r]*b[y])%MOD;}}}
            else{for(int i=q;i<end;i++){int target=d+i-q;for(int r=0;r<d;r++){int y=target-r;if(y<2*d)c[i]=(c[i]+a[q-d+r]*b[y]+b[q-d+r]*a[y])%MOD;}}}
        }
    }
    for(int i=0;i<n;i++){ulong x=(ulong)c[i];for(int j=0;j<4;j++)output[4*i+j]=(uint8)(x>>(8*j));}return 4*n;
}
