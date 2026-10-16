fn putI64Le(out: []u8, offset: usize, value: i64) void {
    const bits: u64=@bitCast(value);
    for(0..8)|b| out[offset+b]=@truncate(bits>>@intCast(8*b));
}
export fn floor_and_ceiling(input:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64 {
    if(input==null || length<3 || length>384)return -1;
    const v=input.?[0..length];const raw_n=v[0];const root=v[1];const key=v[2];
    if(raw_n<0 || raw_n>127 || key < -1_000_000 || key>1_000_000 || length!=3+3*@as(usize,@intCast(raw_n)))return -1;
    const n:usize=@intCast(raw_n);
    if((n==0 && root != -1)||(n>0 && (root<0 || root>=raw_n)))return -1;
    var floor:i64=@bitCast(@as(u64,0x8000000000000000));var ceiling:i64=floor;
    var current:usize=n;if(n>0)current=@intCast(root);
    for(0..n)|_|{
        if(current>=n)break;
        const base=3+3*current;const value=v[base];const left=v[base+1];const right=v[base+2];
        if(value < -1_000_000 || value>1_000_000 || left < -1 || right < -1 || left>=raw_n || right>=raw_n)return -1;
        if(value==key){floor=value;ceiling=value;break;}
        if(key<value){ceiling=value;current=if(left<0)n else @intCast(left);}
        else{floor=value;current=if(right<0)n else @intCast(right);}
    }
    if(output==null || capacity<16)return -2;
    const out=output.?[0..16];putI64Le(out,0,floor);putI64Le(out,8,ceiling);return 16;
}
