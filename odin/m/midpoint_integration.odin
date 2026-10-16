package midpoint_integration
import "core:c"
import "core:math"
store :: proc(out:[^]u8,x:i64){u:=transmute(u64)x;for b:=0;b<8;b+=1{out[b]=u8(u>>u64(8*b))}}
@(export)
midpoint_integration :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length!=4 do return -1;f:=input[0];steps:=input[1];aa:=input[2];bb:=input[3];if f<0||f>2||steps<1||steps>256||aa< -1_000_000||aa>1_000_000||bb<aa||bb>1_000_000 do return -1;if output==nil||capacity<8 do return -2;a:=f64(aa)/1e6;b:=f64(bb)/1e6;h:=(b-a)/f64(steps);sum:=f64(0);for i:=i64(0);i<steps;i+=1{x:=a+f64(i)*h+h/2;y:=if f==0{1.0}else if f==1{x}else{x*x};sum+=y};return i64(math.floor(h*sum*1e9+0.5))}
