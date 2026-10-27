module secretary_1e_threshold;
const usz MAX_N=16; const usz MAX_INPUT=17;
const usz[17] SAMPLE={0,0,0,1,1,1,2,2,2,3,3,4,4,4,5,5,5};
fn void put64(char*out,usz at,long value){ulong bits=(ulong)value;for(usz j=0;j<8;j+=1){out[at+j]=(char)(bits&255);bits>>=8;}}

long secretary_1e_threshold(long*in,usz len,char*out,usz cap) @export("secretary_1e_threshold") {
    if(in==null||len<4||len>MAX_INPUT)return -1;
    long n64=in[0];if(n64<3||n64>(long)MAX_N||len!=(usz)(n64+1))return -1;usz n=(usz)n64;
    char[MAX_N+1] seen=zeroed;
    for(usz i=0;i<n;i+=1){long rank=in[i+1];if(rank<1||rank>n64||seen[(usz)rank]!=0)return -1;seen[(usz)rank]=1;}
    usz observed=SAMPLE[n];long threshold=in[1];for(usz i=1;i<observed;i+=1)if(in[i+1]>threshold)threshold=in[i+1];
    long selected=-1;for(usz i=observed;i<n;i+=1)if(in[i+1]>threshold){selected=(long)i;break;}
    if(out==null||cap<8)return -2;char[8] staged=zeroed;put64(&staged[0],0,selected);for(usz i=0;i<8;i+=1)out[i]=staged[i];return 8;
}
