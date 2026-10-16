package line_sweep
import "core:c"
line_sweep :: proc(v:[^]i64,n:c.size_t)->f64{if n<1||n>17{return -1e300};count:=v[0];if count<0||count>8||n!=c.size_t(1+2*count){return -1e300};if count==0{return 0};var line:[22]int;for i:=i64(0);i<count;i+=1{s:=v[1+2*i];e:=v[2+2*i];if s<0||e<s||e>20{return -1e300};line[s]+=1;line[e+1]-=1};cval:=0;m:=0;for d in line{cval+=d;if cval>m{m=cval}};if m>1{return 1};return 0}
