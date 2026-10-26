package first_fit_bin_packing
import "core:c"
put_i64_le :: proc "contextless"(out:[^]u8,off:int,x:i64){u:=transmute(u64)x;for b:=0;b<8;b+=1{out[off+b]=u8(u>>u64(8*b))}}
@(export)
first_fit_bin_packing :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<1||length>65 do return -1
	n64:=input[0];if n64<0||n64>64 do return -1
	n:=int(n64);if length!=c.size_t(1+n) do return -1
	for i:=0;i<n;i+=1{if input[i+1]<1||input[i+1]>1_000_000 do return -1}
	var loads:[64]i64;var ids:[64]i64;bins:=0
	for i:=0;i<n;i+=1{size:=input[i+1];b:=0;for b<bins&&loads[b]+size>1_000_000{b+=1};if b==bins{loads[bins]=size;bins+=1}else{loads[b]+=size};ids[i]=i64(b)}
	required:=(n+1)*8;if capacity<c.size_t(required)||output==nil do return -2
	put_i64_le(output,0,i64(bins));for i:=0;i<n;i+=1{put_i64_le(output,8*(i+1),ids[i])};return i64(required)
}
