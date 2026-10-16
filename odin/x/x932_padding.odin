package x932_padding
import "core:c"
@(export)
x932_padding :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
 if values==nil||length<1||length>257 do return -1; if values[0]<1||values[0]>64 do return -1
 block:=int(values[0]); n:=int(length)-1
 for i:=1;i<int(length);i+=1 { if values[i]<0||values[i]>255 do return -1 }
 pad:=block-(n%block); total:=n+pad
 if total>int(capacity)||output==nil do return -2
 for i:=0;i<n;i+=1 { output[i]=u8(values[i+1]) }
 for i:=n;i<total-1;i+=1 { output[i]=0 }
 output[total-1]=u8(pad); return i64(total)
}
