package deterministic_line_search
import "core:c"
put_i64_le :: proc "contextless"(out:[^]u8,p:int,x:i64){u:=transmute(u64)x;for b:=0;b<8;b+=1{out[p+b]=u8(u>>u64(8*b))}}
@(export)
deterministic_line_search :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length!=1 do return -1;target:=input[0];if target==0||target< -50000||target>50000 do return -1
	distance:=target;if distance<0{distance=-distance};traveled:=i64(0);leg:=i64(0);depth:=i64(1)
	for{negative:=leg%2==0;if (target<0)==negative&&distance<=depth{traveled+=distance;break};traveled+=2*depth;depth*=2;leg+=1}
	if capacity<16||output==nil do return -2;put_i64_le(output,0,traveled);put_i64_le(output,8,leg);return 16
}
