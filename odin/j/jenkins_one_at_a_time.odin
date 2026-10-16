package jenkins_one_at_a_time
import "core:c"
@(export)
jenkins_one_at_a_time :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>65 do return -1;count:=v[0];if count<0||count>64||n!=c.size_t(count+1) do return -1;h:=i64(0);for i:=c.size_t(0);i<c.size_t(count);i+=1{b:=v[i+1];if b<0||b>127 do return -1;h=(h+b)&0xFFFFFFFF;h=(h+(h<<10))&0xFFFFFFFF;h=(h^(h>>6))&0xFFFFFFFF};h=(h+(h<<3))&0xFFFFFFFF;h=(h^(h>>11))&0xFFFFFFFF;h=(h+(h<<15))&0xFFFFFFFF;return h}
