package join
import "core:c"
const MAX_OUTPUT=3040
@(export)
join :: proc "c" (v:[^]i64,n:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if v==nil||n<2||n>2115 do return -1;sl,count:=v[0],v[1];if sl<0||sl>32||count<0||count>32 do return -1;cursor:=c.size_t(2);if c.size_t(sl)>n-cursor do return -1;sep:[32]u8={};for i in 0..<int(sl){x:=v[cursor];cursor+=1;if x<0||x>127 do return -1;sep[i]=u8(x)};result:[MAX_OUTPUT]u8={};written:=0;for item in 0..<int(count){if cursor>=n do return -1;length:=v[cursor];cursor+=1;if length<0||length>64||c.size_t(length)>n-cursor do return -1;if item>0{for j in 0..<int(sl){result[written]=sep[j];written+=1}};for _ in 0..<int(length){x:=v[cursor];cursor+=1;if x<0||x>127 do return -1;result[written]=u8(x);written+=1}};if cursor!=n do return -1;if output==nil||capacity<c.size_t(written) do return -2;for i in 0..<written{output[i]=result[i]};return i64(written)}
