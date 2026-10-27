module distributed_coupon_collection_replay;
const usz MAX_N=8;const usz MAX_INPUT=76;
fn void put64(char*out,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b+=1){out[at+b]=(char)(bits&255);bits>>=8;}}
long distributed_coupon_collection_replay(long*input,usz length,char*output,usz capacity) @export("distributed_coupon_collection_replay"){
    if(input==null||length<4||length>MAX_INPUT)return -1;
    long n64=input[0],c64=input[1],copies=input[2],steps64=input[3];
    if(n64<2||n64>8||c64<1||c64>8||copies<1||copies>n64||steps64<1||steps64>8||length!=4+(usz)n64+(usz)n64*(usz)steps64)return -1;
    usz n=(usz)n64,coupons=(usz)c64,steps=(usz)steps64;ulong full=((ulong)1<<coupons)-1;
    ulong[MAX_N] bins=zeroed;
    for(usz b=0;b<n;b+=1){long raw=input[4+b];if(raw<0||(((ulong)raw)&~full)!=0)return -1;bins[b]=(ulong)raw;}
    for(usz coupon=0;coupon<coupons;coupon+=1){usz count=0;for(usz b=0;b<n;b+=1)if(((bins[b]>>coupon)&1)!=0)count+=1;if(count<(usz)copies)return -1;}
    usz tape_at=4+n;for(usz i=0;i<n*steps;i+=1)if(input[tape_at+i]!=0&&input[tape_at+i]!=1)return -1;
    if(output==null||capacity<16)return -2;
    ulong collected=0;long singleton_steps=0;
    for(usz step=0;step<steps;step+=1){usz open_count=0,opened_bin=0;for(usz bin=0;bin<n;bin+=1)if(input[tape_at+step*n+bin]==1){open_count+=1;opened_bin=bin;}if(open_count==1){singleton_steps+=1;collected|=(ulong)bins[opened_bin];}}
    char[16] staged=zeroed;put64(&staged[0],0,(long)collected);put64(&staged[0],8,singleton_steps);for(usz i=0;i<16;i+=1)output[i]=staged[i];return 16;
}
