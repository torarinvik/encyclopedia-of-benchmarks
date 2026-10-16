package fuzzy_operations
import "core:c"
import "core:math"
putd :: proc(o:[^]u8,p:int,x:f64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{o[p+k]=u8(bits>>u64(k*8))}}
@(export)
fuzzy_operations :: proc "c" (v:[^]i64,n:c.size_t,o:[^]u8,cap:c.size_t)->i64{if v==nil||n!=8 do return -1;op:=v[0];if op<0||op>3 do return -1;for i:=1;i<8;i+=1{if v[i]<0||v[i]>1000 do return -1};if op==0{for i:=4;i<8;i+=1{if v[i]!=0 do return -1}}else if op==1||op==2{if v[7]!=0 do return -1}else if v[4]!=0||v[5]!=0||v[6]!=0||v[1]>=v[2]||v[2]>=v[3]{return -1};size:=c.size_t(24);if op==3{size=8};if o==nil||cap<size do return -2;a:=f64(v[1])/1000.0;b:=f64(v[2])/1000.0;c0:=f64(v[3])/1000.0;if op==0{putd(o,0,1-c0);putd(o,8,1-a);putd(o,16,1-b)}else if op==1{putd(o,0,math.max(a,f64(v[4])/1000.0));putd(o,8,math.min(c0,f64(v[6])/1000.0));putd(o,16,(b+f64(v[5])/1000.0)/2)}else if op==2{putd(o,0,math.min(a,f64(v[4])/1000.0));putd(o,8,(b+f64(v[5])/1000.0)/2);putd(o,16,math.max(c0,f64(v[6])/1000.0))}else{x:=f64(v[7])/1000.0;y:=0.0;if x>a&&x<c0{if x<=b{y=(x-a)/(b-a)}else{y=(c0-x)/(c0-b)}};putd(o,0,y)};return i64(size)}
