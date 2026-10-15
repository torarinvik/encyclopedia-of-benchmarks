package windowed_median
import "core:c"
put_f64_le :: proc "contextless"(value:f64,output:[^]u8,offset:usize){bits:=transmute(u64)value;for b:=0;b<8;b+=1{output[offset+b]=u8(bits>>u64(8*b))}}
@(export)
windowed_median :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3 do return -1
 wv,nv:=input[0],input[1];if wv<1||wv>64||nv<1||nv>128 do return -1
 w,n:=usize(wv),usize(nv);if length!=n+2 do return -1
 for i:usize=0;i<n;i+=1{if input[2+i]<-1000000||input[2+i]>1000000 do return -1}
 if capacity<n*8||output==nil do return -2
 sorted:[64]i64;active:usize=0
 for i:usize=0;i<n;i+=1{
  if i>=w{old:=input[2+i-w];p:usize=0;for p<active&&sorted[p]!=old{p+=1};if p==active do return -1;for j:=p+1;j<active;j+=1{sorted[j-1]=sorted[j]};active-=1}
  value:=input[2+i];p:usize=0;for p<active&&sorted[p]<value{p+=1};j:=active;for j>p{sorted[j]=sorted[j-1];j-=1};sorted[p]=value;active+=1
  median:f32;if active%2==1{median=f32(sorted[active/2])}else{median=0.5*f32(sorted[active/2-1])+0.5*f32(sorted[active/2])};put_f64_le(f64(median),output,i*8)
 }
 return i64(n*8)
}
