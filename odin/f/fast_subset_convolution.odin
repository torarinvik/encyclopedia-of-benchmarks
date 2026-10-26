package fast_subset_convolution

import "core:c"

MOD :: i64(998244353)
rank_of :: proc "contextless" (mask: int) -> int { r:=0; for x:=mask;x>0;x>>=1 {r+=x&1}; return r }
put_i64_le :: proc "contextless" (out:[^]u8,off:int,x:i64){bits:=transmute(u64)x;for b:=0;b<8;b+=1{out[off+b]=u8(bits>>u64(8*b))}}

@(export)
fast_subset_convolution :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil||length<3||length>33 do return -1
	n64:=input[0];if n64<0||n64>4 do return -1
	n:=int(n64);size:=1<<n;if length!=c.size_t(1+2*size) do return -1
	for i:=0;i<2*size;i+=1 {if input[1+i]<0||input[1+i]>=MOD do return -1}
	var f:[5][16]i64;var g:[5][16]i64;var h:[5][16]i64
	for s:=0;s<size;s+=1{r:=rank_of(s);f[r][s]=input[1+s];g[r][s]=input[1+size+s]}
	for bit:=0;bit<n;bit+=1{for s:=0;s<size;s+=1{if s&(1<<bit)!=0{other:=s^(1<<bit);for r:=0;r<=n;r+=1{f[r][s]=(f[r][s]+f[r][other])%MOD;g[r][s]=(g[r][s]+g[r][other])%MOD}}}}
	for s:=0;s<size;s+=1{for r:=0;r<=n;r+=1{sum:i64=0;for i:=0;i<=r;i+=1{sum=(sum+f[i][s]*g[r-i][s])%MOD};h[r][s]=sum}}
	for bit:=0;bit<n;bit+=1{for s:=0;s<size;s+=1{if s&(1<<bit)!=0{other:=s^(1<<bit);for r:=0;r<=n;r+=1{h[r][s]=(h[r][s]-h[r][other]+MOD)%MOD}}}}
	required:=size*8;if capacity<c.size_t(required)||output==nil do return -2
	for s:=0;s<size;s+=1{put_i64_le(output,8*s,h[rank_of(s)][s])};return i64(required)
}
