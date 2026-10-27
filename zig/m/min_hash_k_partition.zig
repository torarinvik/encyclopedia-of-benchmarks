const K:usize=8;const N:usize=32;const EMPTY:i64=1001;
fn putI64(out:[*]u8,pos:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[pos+b]=@truncate(bits>>@intCast(8*b));}
export fn min_hash_k_partition(input:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64{
 const values=input orelse return -1;if(length<2 or length>66)return -1;
 const k0=values[0];const n0=values[1];if(k0<1 or k0>8 or n0<0 or n0>32 or length!=2+2*@as(usize,@intCast(n0)))return -1;
 const k:usize=@intCast(k0);const n:usize=@intCast(n0);var ids=[_]i64{-1}**K;var ranks=[_]i64{EMPTY}**K;
 for(0..n)|id|{const bucket=values[2+2*id];const rank=values[3+2*id];if(bucket<0 or bucket>=k0 or rank<0 or rank>1000)return -1;const b:usize=@intCast(bucket);if(ids[b]<0 or rank<ranks[b] or (rank==ranks[b] and @as(i64,@intCast(id))<ids[b])){ids[b]=@intCast(id);ranks[b]=rank;}}
 var staged=[_]i64{0}**(2*K);for(0..k)|b|{staged[2*b]=ids[b];staged[2*b+1]=ranks[b];}
 const required=2*k*8;const out=output orelse return -2;if(capacity<required)return -2;for(0..2*k)|i|putI64(out,i*8,staged[i]);return @intCast(required);
}
