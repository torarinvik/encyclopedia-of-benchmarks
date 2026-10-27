module sensor_energy_balance_estimator_trace;
const usz MAX_N=8;const usz MAX_INPUT=82;const usz MAX_OUTPUT=72;const long INPUT_SCALE=1000000;
fn long gcd64(long a,long b){while(b!=0){long r=a%b;a=b;b=r;}return a;}
fn void put64(char*out,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b+=1){out[at+b]=(char)(bits&255);bits>>=8;}}
long sensor_energy_balance_estimator_trace(long*input,usz length,char*output,usz capacity) @export("sensor_energy_balance_estimator_trace"){
    if(input==null||length<4||length>MAX_INPUT)return -1;
    long n64=input[0],h64=input[1];if(n64<1||n64>8||h64<1||h64>8||length!=2+(usz)n64+(usz)h64+(usz)n64*(usz)h64)return -1;
    usz n=(usz)n64,h=(usz)h64;long[MAX_N] lambda=zeroed;long sum=0;
    for(usz i=0;i<n;i+=1){lambda[i]=input[2+i];if(lambda[i]<0||lambda[i]>INPUT_SCALE)return -1;sum+=lambda[i];}if(sum!=INPUT_SCALE)return -1;
    ulong full=((ulong)1<<n)-1;usz path_at=2+n;for(usz t=0;t<h;t+=1){long mask=input[path_at+t];if(mask<=0||(((ulong)mask)&~full)!=0)return -1;}
    long lcm=1;for(long t=2;t<=h64;t+=1)lcm=(lcm/gcd64(lcm,t))*t;long q=INPUT_SCALE*lcm;usz draw_at=path_at+h;
    for(usz i=0;i<n*h;i+=1)if(input[draw_at+i]<0||input[draw_at+i]>=q)return -1;
    long[MAX_N] state=zeroed;for(usz i=0;i<n;i+=1)state[i]=lambda[i]*lcm;
    for(usz t=0;t<h;t+=1){long divisor=(long)t+1,delta=q/divisor;ulong path=(ulong)input[path_at+t];for(usz i=0;i<n;i+=1){if(state[i]<0||state[i]>q)return -1;long r=input[draw_at+t*n+i]<state[i]?1:0;long x=(long)((path>>i)&1);long updated=state[i]+(x-r)*delta;if(updated<0||updated>q)return -1;state[i]=updated;}}
    usz bytes=8*(1+n);if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put64(&staged[0],0,q);for(usz i=0;i<n;i+=1)put64(&staged[0],8*(i+1),state[i]);for(usz i=0;i<bytes;i+=1)output[i]=staged[i];return (long)bytes;
}
