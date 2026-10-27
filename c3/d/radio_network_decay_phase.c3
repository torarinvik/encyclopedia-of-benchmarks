module radio_network_decay_phase;
const usz MAX_N=8;const usz MAX_K=8;const usz MAX_INPUT=75;
fn void put64(char *out,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b+=1){out[offset+b]=(char)(bits&255);bits>>=8;}}
long radio_network_decay_phase(long *input,usz length,char *output,usz capacity) @export("radio_network_decay_phase"){
    if(input==null||length<3||length>MAX_INPUT)return -1;
    long n64=input[0],k64=input[1],initial=input[2];
    if(n64<2||n64>8||k64<1||k64>8||length!=3+(usz)n64+(usz)n64*(usz)k64)return -1;
    usz n=(usz)n64,k=(usz)k64;ulong full=((ulong)1<<n)-1;
    if(initial<=0||(((ulong)initial)&~full)!=0)return -1;
    ulong[MAX_N] adjacency=zeroed;
    for(usz v=0;v<n;v+=1){long raw=input[3+v];if(raw<0||(((ulong)raw)&~full)!=0||(((ulong)raw)&((ulong)1<<v))!=0)return -1;adjacency[v]=(ulong)raw;}
    for(usz u=0;u<n;u+=1)for(usz v=0;v<n;v+=1)if(((adjacency[u]>>v)&1)!=((adjacency[v]>>u)&1))return -1;
    usz tape_at=3+n;for(usz i=0;i<n*k;i+=1)if(input[tape_at+i]!=0&&input[tape_at+i]!=1)return -1;
    if(output==null||capacity<16)return -2;
    bool[MAX_N] active=zeroed;for(usz v=0;v<n;v+=1)active[v]=(((ulong)initial>>v)&1)!=0;
    ulong newly=0;long transmissions=0;
    for(usz slot=0;slot<k;slot+=1){
        for(usz sender=0;sender<n;sender+=1)if(active[sender])transmissions+=1;
        for(usz receiver=0;receiver<n;receiver+=1){if((((ulong)initial>>receiver)&1)!=0)continue;usz count=0;for(usz sender=0;sender<n;sender+=1)if(active[sender]&&((adjacency[sender]>>receiver)&1)!=0)count+=1;if(count==1)newly|=(ulong)1<<receiver;}
        for(usz sender=0;sender<n;sender+=1)if(active[sender]&&(input[tape_at+sender*k+slot]==0||slot+1==k))active[sender]=false;
    }
    char[16] staged=zeroed;put64(&staged[0],0,(long)newly);put64(&staged[0],8,transmissions);for(usz i=0;i<16;i+=1)output[i]=staged[i];return 16;
}
