package ams_sketch
import "core:c"
put_i64_le :: proc "contextless"(out:[^]u8,x:i64){u:=transmute(u64)x;for b:=0;b<8;b+=1{out[b]=u8(u>>u64(8*b))}}
@(export)
ams_sketch :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<4||length>116 do return -1
	d0,w0,k0,u0:=input[0],input[1],input[2],input[3]
	if (d0!=1&&d0!=3&&d0!=5)||w0<1||w0>8||k0<1||k0>8||u0<0||u0>16 do return -1
	d,w,k,u:=int(d0),int(w0),int(k0),int(u0);start:=4+2*d*k;if length!=c.size_t(start+2*u) do return -1
	for r:=0;r<d;r+=1{for key:=0;key<k;key+=1{p:=4+2*(r*k+key);if input[p]<0||input[p]>=w0||(input[p+1]!=-1&&input[p+1]!=1) do return -1}}
	for i:=0;i<u;i+=1{key,weight:=input[start+2*i],input[start+2*i+1];if key<0||key>=k0||weight< -1000||weight>1000 do return -1}
	var counters:[5][8]i64;var estimates:[5]i64
	for i:=0;i<u;i+=1{key:=int(input[start+2*i]);weight:=input[start+2*i+1];for r:=0;r<d;r+=1{p:=4+2*(r*k+key);b:=int(input[p]);counters[r][b]+=weight*input[p+1]}}
	for r:=0;r<d;r+=1{for b:=0;b<w;b+=1{estimates[r]+=counters[r][b]*counters[r][b]}}
	for i:=1;i<d;i+=1{x:=estimates[i];j:=i;for j>0&&estimates[j-1]>x{estimates[j]=estimates[j-1];j-=1};estimates[j]=x}
	if capacity<8||output==nil do return -2
	put_i64_le(output,estimates[d/2]);return 8
}
