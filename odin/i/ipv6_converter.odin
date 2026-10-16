package ipv6_converter
import "core:c"
@(export)
ipv6_converter :: proc "c" (a:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{if a==nil||n<2 do return -1;op:=a[0];len:=a[1];if !((op==0&&len==4)||(op==1&&len==16))||n!=c.size_t(2+len)do return -1;for i:=c.size_t(0);i<c.size_t(len);i+=1{if a[i+2]<0||a[i+2]>255 do return -1};if op==1{for i:=0;i<10;i+=1{if a[i+2]!=0 do return -1};if a[12]!=255||a[13]!=255 do return -1};needed:=c.size_t(4);if op==0{needed=16};if out==nil||cap<needed do return -2;if op==0{for i:=0;i<10;i+=1{out[i]=0};out[10]=255;out[11]=255;for i:=0;i<4;i+=1{out[12+i]=u8(a[2+i])}}else{for i:=0;i<4;i+=1{out[i]=u8(a[14+i])}};return i64(needed)}
