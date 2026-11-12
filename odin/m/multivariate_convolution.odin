package multivariate_convolution
import "core:c"
MAX_K :: 3
MAX_P :: 32
MAX_INPUT :: 69
MAX_OUTPUT :: 256
MOD :: i64(998244353)
store_le :: proc(output:[^]u8,offset:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[offset+b]=u8(bits&255);bits>>=8}}
@(export)
multivariate_convolution :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<1||length>MAX_INPUT do return -1
	k0:=input[0];if k0<0||k0>MAX_K do return -1;k:=int(k0);if length<c.size_t(1+k) do return -1
	dims:[MAX_K]int={};p:=1
	for axis:=0;axis<k;axis+=1{d0:=input[1+axis];if d0<2||d0>MAX_P||p>MAX_P/int(d0) do return -1;dims[axis]=int(d0);p*=dims[axis]}
	start:=1+k;if length!=c.size_t(start+2*p) do return -1
	for q:=start;q<int(length);q+=1{if input[q]<0||input[q]>=MOD do return -1}
	bytes:=8*p;if bytes>MAX_OUTPUT do return -1;if output==nil||capacity<c.size_t(bytes) do return -2
	a,b,result:[MAX_P]i64={},{},{}
	for i:=0;i<p;i+=1{a[i]=input[start+i];b[i]=input[start+p+i]}
	for i:=0;i<p;i+=1{for j:=0;j<p;j+=1{target:=0;stride:=1;valid:=true;for axis:=0;axis<k;axis+=1{d:=dims[axis];sum:=(i/stride)%d+(j/stride)%d;if sum>=d{valid=false;break};target+=sum*stride;stride*=d};if valid{result[target]=(result[target]+a[i]*b[j])%MOD}}}
	for i:=0;i<p;i+=1{store_le(output,8*i,result[i])};return i64(bytes)
}
