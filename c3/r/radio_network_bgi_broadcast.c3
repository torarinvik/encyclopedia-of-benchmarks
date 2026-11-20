module radio_network_bgi_broadcast;
const usz MAX_N=8; const usz MAX_INPUT=203; const usz MAX_OUTPUT=88;

fn usz ceil_log2(usz value) { usz exponent=0; usz power=1; while(power<value){power<<=1;exponent+=1;} return exponent; }
fn void put64(char *out, usz offset, long value) { ulong bits=(ulong)value; for(usz b=0;b<8;b+=1){out[offset+b]=(char)(bits&255);bits>>=8;} }

fn long radio_network_bgi_broadcast(long *input, usz length, char *output, usz capacity) @export("radio_network_bgi_broadcast") {
    if(input==null||length<3||length>MAX_INPUT)return -1;
    long n64=input[0],source64=input[1],delta64=input[2];
    if(n64<2||n64>8||source64<0||source64>=n64||delta64<2||delta64>8)return -1;
    usz n=(usz)n64,source=(usz)source64,delta=(usz)delta64;
    usz k=2*ceil_log2(delta),t=ceil_log2(2*n),tape_at=3+n,tape_count=n*t*k;
    if(length!=tape_at+tape_count)return -1;
    ulong full=((ulong)1<<n)-1; ulong[MAX_N] adjacency=zeroed;
    for(usz v=0;v<n;v+=1){long raw=input[3+v];if(raw<0||(((ulong)raw)&~full)!=0||(((ulong)raw)&((ulong)1<<v))!=0)return -1;adjacency[v]=(ulong)raw;usz degree=0;for(usz u=0;u<n;u+=1)if(((adjacency[v]>>u)&1)!=0)degree+=1;if(degree>delta)return -1;}
    for(usz u=0;u<n;u+=1)for(usz v=0;v<n;v+=1)if(((adjacency[u]>>v)&1)!=((adjacency[v]>>u)&1))return -1;
    for(usz i=0;i<tape_count;i+=1)if(input[tape_at+i]!=0&&input[tape_at+i]!=1)return -1;
    usz output_bytes=8*(n+3);if(output==null||capacity<output_bytes)return -2;
    bool[MAX_N] informed=zeroed;bool[MAX_N] active=zeroed;bool[MAX_N] newly=zeroed;usz[MAX_N] calls=zeroed;long[MAX_N] first_slot;
    for(usz v=0;v<n;v+=1)first_slot[v]=-1;informed[source]=true;first_slot[source]=0;
    long transmissions=0,phases=0;
    for(usz phase=0;phase<n*t;phase+=1){usz starters=0;for(usz v=0;v<n;v+=1){active[v]=informed[v]&&calls[v]<t;newly[v]=false;if(active[v])starters+=1;}if(starters==0)break;
        for(usz slot=0;slot<k;slot+=1){for(usz sender=0;sender<n;sender+=1)if(active[sender])transmissions+=1;
            for(usz receiver=0;receiver<n;receiver+=1){if(informed[receiver]||newly[receiver])continue;usz senders=0;for(usz sender=0;sender<n;sender+=1)if(active[sender]&&((adjacency[sender]>>receiver)&1)!=0)senders+=1;if(senders==1){newly[receiver]=true;first_slot[receiver]=(long)(phase*k+slot);}}
            for(usz sender=0;sender<n;sender+=1)if(active[sender]){usz at=tape_at+(sender*t+calls[sender])*k+slot;if(slot+1==k||input[at]==0)active[sender]=false;}
        }
        for(usz v=0;v<n;v+=1){if(informed[v]&&calls[v]<t)calls[v]+=1;if(newly[v])informed[v]=true;}phases=(long)(phase+1);
    }
    char[MAX_OUTPUT] staged=zeroed;put64(&staged[0],0,n64);put64(&staged[0],8,phases);put64(&staged[0],16,transmissions);for(usz v=0;v<n;v+=1)put64(&staged[0],24+8*v,first_slot[v]);for(usz i=0;i<output_bytes;i+=1)output[i]=staged[i];return (long)output_bytes;
}
