package min_hash_k_partition
import "core:c"
K :: 8
N :: 32
EMPTY :: 1001
put_i64 :: proc(out:[^]u8,pos:int,value:i64){bits:=u64(value);for b in 0..<8{out[pos+b]=u8((bits>>(8*b))&255)}}
@(export)
min_hash_k_partition :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2||length>66 do return -1
 k0:=input[0];n0:=input[1]
 if k0<1||k0>K||n0<0||n0>N||length!=c.size_t(2+2*n0) do return -1
 ids:[K]i64; ranks:[K]i64
 for b in 0..<int(k0){ids[b]=-1;ranks[b]=EMPTY}
 for id in 0..<int(n0){bucket:=input[2+2*id];rank:=input[3+2*id];if bucket<0||bucket>=k0||rank<0||rank>1000 do return -1
  b:=int(bucket);if ids[b]<0||rank<ranks[b]||(rank==ranks[b]&&i64(id)<ids[b]){ids[b]=i64(id);ranks[b]=rank}}
 staged:[2*K]i64
 for b in 0..<int(k0){staged[2*b]=ids[b];staged[2*b+1]=ranks[b]}
 required:=2*int(k0)*8;if output==nil||capacity<c.size_t(required) do return -2
 for i in 0..<2*int(k0){put_i64(output,i*8,staged[i])};return i64(required)
}
