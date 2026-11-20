module k_quadtree_sampled_point_subdivision;

fn void put_i64_le(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) out[at+b] = (char)(bits >> (8*b));
}

fn long k_quadtree_sampled_point_subdivision(long* input, usz length, char* output,
                                             usz capacity) @export("k_quadtree_sampled_point_subdivision") {
    if (input == null || length < 3 || length > 68) return -1;
    long nv=input[0], kv=input[1], dv=input[2];
    if (nv<1 || nv>32 || kv<1 || kv>nv || dv<1 || dv>8) return -1;
    usz n=(usz)nv, k=(usz)kv, depth=(usz)dv;
    if (length != 3+2*n) return -1;
    ulong side=1UL<<depth;
    ulong[32] keys;
    for (usz i=0;i<n;i++) {
        long x=input[3+2*i], y=input[4+2*i];
        if (x<0 || y<0 || (ulong)x>=side || (ulong)y>=side) return -1;
        ulong key=0;
        for (long bit=(long)depth-1;bit>=0;bit--)
            key=(key<<2)|((((ulong)x>>bit)&1UL)<<1)|(((ulong)y>>bit)&1UL);
        keys[i]=key;
    }
    for (usz i=1;i<n;i++) { ulong value=keys[i]; usz j=i; while(j>0 && keys[j-1]>value){keys[j]=keys[j-1];j--;} keys[j]=value; }
    for (usz i=1;i<n;i++) if(keys[i]==keys[i-1]) return -1;
    usz samples=(n-1)/k+1;
    usz[31] split_depth; ulong[31] split_prefix; usz count=0;
    for (usz i=0;i+1<samples;i++) {
        ulong a=keys[i*k], b=keys[(i+1)*k]; usz common=0;
        while(common<depth){usz shift=2*(depth-common-1);if(((a>>shift)&3UL)!=((b>>shift)&3UL))break;common++;}
        ulong prefix=common==0?0:a>>(2*(depth-common));
        usz j=0;while(j<count && (split_depth[j]!=common || split_prefix[j]!=prefix))j++;
        if(j==count){split_depth[count]=common;split_prefix[count]=prefix;count++;}
    }
    for(usz i=1;i<count;i++){
        usz d=split_depth[i];ulong p=split_prefix[i], start=p<<(2*(depth-d));usz j=i;
        while(j>0){ulong ps=split_prefix[j-1]<<(2*(depth-split_depth[j-1]));if(ps<start||(ps==start&&split_depth[j-1]<=d))break;split_depth[j]=split_depth[j-1];split_prefix[j]=split_prefix[j-1];j--;}
        split_depth[j]=d;split_prefix[j]=p;
    }
    usz bytes=8*(1+2*count);if(output==null||capacity<bytes)return -2;
    put_i64_le(output,0,(long)count);
    for(usz i=0;i<count;i++){put_i64_le(output,8*(1+2*i),(long)split_depth[i]);put_i64_le(output,8*(2+2*i),(long)split_prefix[i]);}
    return (long)bytes;
}
