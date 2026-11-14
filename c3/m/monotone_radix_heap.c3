module monotone_radix_heap;

fn usz bucket_of(uint key, uint last) {
    uint difference=key^last;
    usz bits=0;
    while (difference!=0) { bits++; difference>>=1; }
    return bits;
}

fn long monotone_radix_heap(long* input, usz length) @export("monotone_radix_heap") {
    if (input==null || length<1 || length>130 || input[0]<0 || input[0]>64) return -1;
    usz q=input[0].usz();
    if (length!=1+2*q) return -1;
    int[32] heads; int[64] next; uint[64] keys;
    for (usz i=0; i<32; i++) heads[i]=-1;
    int used=0; long removals=0, result=0; uint last=0;
    for (usz i=0; i<q; i++) {
        long op=input[1+2*i], key=input[2+2*i];
        if (op==0) {
            if (key<(long)last || key>2147483647) return -1;
            uint value=(uint)key;
            usz bucket=bucket_of(value,last);
            keys[used]=value; next[used]=heads[bucket]; heads[bucket]=used++;
        } else if (op==1 && key==0) {
            if (heads[0]<0) {
                usz bucket=1;
                while (bucket<32 && heads[bucket]<0) bucket++;
                if (bucket==32) return -1;
                uint smallest=0xffffffff;
                int node=heads[bucket];
                while (node>=0) { if (keys[node]<smallest) smallest=keys[node]; node=next[node]; }
                last=smallest; node=heads[bucket]; heads[bucket]=-1;
                while (node>=0) {
                    int following=next[node]; usz destination=bucket_of(keys[node],last);
                    next[node]=heads[destination]; heads[destination]=node; node=following;
                }
            }
            int node=heads[0]; heads[0]=next[node];
            result+=(++removals)*(long)keys[node];
        } else return -1;
    }
    return result;
}
