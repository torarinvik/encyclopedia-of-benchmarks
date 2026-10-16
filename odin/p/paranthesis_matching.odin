package paranthesis_matching
import "core:c"
@(export)
paranthesis_matching :: proc "c" (v:[^]i64,n:c.size_t)->i64{
 if v==nil||n<2||n>100 do return -1;count:=v[0];if count<1||count>99||n!=c.size_t(count+1) do return -1
 st:[99]i64;sp:=0
 for i:=1;i<int(n);i+=1{x:=v[i];if x<33||x>126 do return -1;if x==40||x==123||x==91||x==60{st[sp]=x;sp+=1}else if x==41||x==125||x==93||x==62{want:=i64(60);if x==41{want=40}else if x==125{want=123}else if x==93{want=91};if sp==0 do return 0;sp-=1;if st[sp]!=want do return 0}else{return 0}}
 if sp==0 do return 1;return 0
}
