module private_noisy_power_iteration;
const long SCALE=1000000;const usz MAX_N=4;const usz MAX_L=4;const usz MAX_INPUT=39;

fn long trunc_div(long numerator,long denominator){if(numerator<0)return -((-numerator)/denominator);return numerator/denominator;}
fn long floor_sqrt(long value){long low=0,high=13000001;while(low+1<high){long middle=(low+high)/2;if(middle<=value/middle)low=middle;else high=middle;}return low;}
fn void put64(char*out,usz pos,long value){ulong bits=(ulong)value;for(usz j=0;j<8;j+=1){out[pos+j]=(char)(bits&255);bits>>=8;}}

long private_noisy_power_iteration(long*in,usz len,char*out,usz cap) @export("private_noisy_power_iteration") {
    if(in==null||len<11||len>MAX_INPUT)return -1;
    long n64=in[0],l64=in[1],sigma=in[2];
    if(n64<2||n64>(long)MAX_N||l64<1||l64>(long)MAX_L||sigma<0||sigma>SCALE||len!=3+(usz)n64*(usz)n64+(usz)n64+(usz)l64*(usz)n64)return -1;
    usz n=(usz)n64,rounds=(usz)l64,vector_start=3+n*n,noise_start=vector_start+n;
    long[MAX_N*MAX_N] matrix=zeroed;long[MAX_N] x=zeroed;long[MAX_L*MAX_N] noise=zeroed;
    for(usz i=0;i<n*n;i+=1){matrix[i]=in[3+i];if(matrix[i]<-SCALE||matrix[i]>SCALE)return -1;}
    for(usz i=0;i<n;i+=1)for(usz j=0;j<n;j+=1)if(matrix[i*n+j]!=matrix[j*n+i])return -1;
    long initial_norm=0;
    for(usz i=0;i<n;i+=1){x[i]=in[vector_start+i];if(x[i]<-SCALE||x[i]>SCALE)return -1;initial_norm+=x[i]*x[i];}
    if(initial_norm!=SCALE*SCALE)return -1;
    for(usz i=0;i<rounds*n;i+=1){noise[i]=in[noise_start+i];if(noise[i]<-2*SCALE||noise[i]>2*SCALE)return -1;}
    long[MAX_N] y=zeroed;
    for(usz step=0;step<rounds;step+=1){long norm_sq=0;for(usz i=0;i<n;i+=1){long sum=sigma*noise[step*n+i];for(usz j=0;j<n;j+=1)sum+=matrix[i*n+j]*x[j];y[i]=trunc_div(sum,SCALE);norm_sq+=y[i]*y[i];}if(norm_sq==0)return -1;long radius=floor_sqrt(norm_sq);for(usz i=0;i<n;i+=1)x[i]=trunc_div(y[i]*SCALE,radius);}
    usz bytes=8*n;if(out==null||cap<bytes)return -2;
    char[8*MAX_N] staged=zeroed;for(usz i=0;i<n;i+=1)put64(staged,8*i,x[i]);for(usz i=0;i<bytes;i+=1)out[i]=staged[i];return (long)bytes;
}
