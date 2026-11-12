package multivariate_convolution_cyclic
import "core:c"
MAX_K :: 3
MAX_P :: 32
MAX_INPUT :: 70
MAX_OUTPUT :: 256
is_prime :: proc(p:int)->bool{if p<2 do return false;for d:=2;d*d<=p;d+=1{if p%d==0 do return false};return true}
store_le :: proc(output:[^]u8,offset:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[offset+b]=u8(bits&255);bits>>=8}}
@(export)
multivariate_convolution_cyclic :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<2||length>MAX_INPUT do return -1
	p0,k0:=input[0],input[1];if p0<2||p0>97||!is_prime(int(p0))||k0<0||k0>MAX_K do return -1
	p,k:=int(p0),int(k0);if length<c.size_t(2+k) do return -1;dims:[MAX_K]int={};product:=1
	for axis:=0;axis<k;axis+=1{d0:=input[2+axis];if d0<2||d0>MAX_P||(p-1)%int(d0)!=0||product>MAX_P/int(d0) do return -1;dims[axis]=int(d0);product*=dims[axis]}
	start:=2+k;if length!=c.size_t(start+2*product) do return -1
	for q:=start;q<int(length);q+=1{if input[q]<0||input[q]>=p0 do return -1}
	bytes:=8*product;if bytes>MAX_OUTPUT do return -1;if output==nil||capacity<c.size_t(bytes) do return -2
	a,b,result:[MAX_P]i64={},{},{}
	for i:=0;i<product;i+=1{a[i]=input[start+i];b[i]=input[start+product+i]}
	for i:=0;i<product;i+=1{for j:=0;j<product;j+=1{target:=0;stride:=1;for axis:=0;axis<k;axis+=1{d:=dims[axis];sum:=((i/stride)%d+(j/stride)%d)%d;target+=sum*stride;stride*=d};result[target]=(result[target]+a[i]*b[j])%p0}}
	for i:=0;i<product;i+=1{store_le(output,8*i,result[i])};return i64(bytes)
}
