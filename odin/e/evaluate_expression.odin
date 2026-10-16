package evaluate_expression
import "core:c"
put32 :: proc(o:[^]u8,x:u32){for k:=0;k<4;k+=1{o[k]=u8(x>>(8*k))}}
putf :: proc(o:[^]u8,x:f64){b:=transmute(u64)x;for k:=0;k<8;k+=1{o[4+k]=u8(b>>(8*k))}}
@(export)
evaluate_expression :: proc "c"(v:[^]i64,n:c.size_t,o:[^]u8,cap:c.size_t)->i64{if v==nil||n<3||n>131 do return -1;count:=v[0];if count<1||count>64||n!=c.size_t(1+2*count) do return -1;st:[64]f64{};depth:=0;valid:=true;for i:=i64(0);i<count;i+=1{op:=v[1+2*i];x:=v[2+2*i];if op==0{if x < -1000000000||x>1000000000 do return -1;st[depth]=f64(x)/1000;depth+=1}else if op>=1&&op<=4{if x!=0 do return -1;if depth<2{valid=false;break};depth-=1;r:=st[depth];depth-=1;l:=st[depth];if op==1{st[depth]=l+r}else if op==2{st[depth]=l-r}else if op==3{st[depth]=l*r}else if r==0{valid=false;break}else{st[depth]=l/r};depth+=1}else{valid=false;break}};valid=valid&&depth==1;need:=c.size_t(4);if valid{need=12};if o==nil||cap<need do return -2;put32(o, u32(if valid{1}else{0}));if valid{putf(o,st[0])};return i64(need)}
