fn bucketOf(key: u32, last: u32) usize {
    var difference=key^last;
    var bits: usize=0;
    while (difference!=0) { bits+=1; difference>>=1; }
    return bits;
}

export fn monotone_radix_heap(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt==null or length<1 or length>130) return -1;
    const input=input_opt.?;
    if (input[0]<0 or input[0]>64) return -1;
    const q: usize=@intCast(input[0]);
    if (length!=1+2*q) return -1;
    var heads=[_]i64{-1} ** 32;
    var next=[_]i64{-1} ** 64;
    var keys=[_]u32{0} ** 64;
    var used: usize=0;
    var last: u32=0;
    var removals: i64=0;
    var result: i64=0;
    for (0..q) |i| {
        const op=input[1+2*i]; const key=input[2+2*i];
        if (op==0) {
            if (key<@as(i64,last) or key>2147483647) return -1;
            const value: u32=@intCast(key);
            const bucket=bucketOf(value,last);
            keys[used]=value; next[used]=heads[bucket]; heads[bucket]=@intCast(used); used+=1;
        } else if (op==1 and key==0) {
            if (heads[0]<0) {
                var bucket: usize=1;
                while (bucket<32 and heads[bucket]<0) : (bucket+=1) {}
                if (bucket==32) return -1;
                var smallest: u32=4294967295;
                var node=heads[bucket];
                while (node>=0) {
                    const index: usize=@intCast(node);
                    smallest=@min(smallest,keys[index]); node=next[index];
                }
                last=smallest; node=heads[bucket]; heads[bucket]=-1;
                while (node>=0) {
                    const index: usize=@intCast(node);
                    const following=next[index]; const destination=bucketOf(keys[index],last);
                    next[index]=heads[destination]; heads[destination]=node; node=following;
                }
            }
            const index: usize=@intCast(heads[0]);
            heads[0]=next[index]; removals+=1;
            result+=removals*@as(i64,keys[index]);
        } else return -1;
    }
    return result;
}
