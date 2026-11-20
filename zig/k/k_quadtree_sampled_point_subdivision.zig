fn putI64Le(output: [*c]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[at+b] = @truncate(bits >> @intCast(8*b));
}

pub export fn k_quadtree_sampled_point_subdivision(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if(input==null or length<3 or length>68)return -1;
    const nv=input[0];const kv=input[1];const dv=input[2];
    if(nv<1 or nv>32 or kv<1 or kv>nv or dv<1 or dv>8)return -1;
    const n:usize=@intCast(nv);const k:usize=@intCast(kv);const depth:usize=@intCast(dv);
    if(length!=3+2*n)return -1;
    const side:i64=@as(i64,1)<<@intCast(depth);
    var keys:[32]u32=@splat(0);
    for(0..n)|i|{
        const x=input[3+2*i];const y=input[4+2*i];if(x<0 or y<0 or x>=side or y>=side)return -1;
        var key:u32=0;var bit:usize=depth;
        while(bit>0){bit-=1;const ux:u32=@intCast(x);const uy:u32=@intCast(y);key=(key<<2)|((((ux>>@intCast(bit))&1)<<1)|((uy>>@intCast(bit))&1));}
        keys[i]=key;
    }
    for(1..n)|i|{const value=keys[i];var j=i;while(j>0 and keys[j-1]>value){keys[j]=keys[j-1];j-=1;}keys[j]=value;}
    for(1..n)|i|{if(keys[i]==keys[i-1])return -1;}
    const samples=(n-1)/k+1;var split_depth:[31]usize=@splat(0);var split_prefix:[31]u32=@splat(0);var count:usize=0;
    var i:usize=0;while(i+1<samples):(i+=1){
        const a=keys[i*k];const b=keys[(i+1)*k];var common:usize=0;
        while(common<depth){const shift: u5=@intCast(2*(depth-common-1));if(((a>>shift)&3)!=((b>>shift)&3))break;common+=1;}
        const prefix:u32=if(common==0)0 else a>>@intCast(2*(depth-common));var j:usize=0;
        while(j<count and (split_depth[j]!=common or split_prefix[j]!=prefix)):(j+=1){}
        if(j==count){split_depth[count]=common;split_prefix[count]=prefix;count+=1;}
    }
    i=1;while(i<count):(i+=1){
        const d=split_depth[i];const p=split_prefix[i];const start=p<<@intCast(2*(depth-d));var j=i;
        while(j>0){const ps=split_prefix[j-1]<<@intCast(2*(depth-split_depth[j-1]));if(ps<start or (ps==start and split_depth[j-1]<=d))break;split_depth[j]=split_depth[j-1];split_prefix[j]=split_prefix[j-1];j-=1;}
        split_depth[j]=d;split_prefix[j]=p;
    }
    const bytes=8*(1+2*count);if(output==null or capacity<bytes)return -2;
    putI64Le(output,0,@intCast(count));for(0..count)|j|{putI64Le(output,8*(1+2*j),@intCast(split_depth[j]));putI64Le(output,8*(2+2*j),@intCast(split_prefix[j]));}
    return @intCast(bytes);
}
