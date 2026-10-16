package ewma_change_detector
import "core:c"
import "core:runtime"
@(export)
ewma_change_detector :: proc "c" (v:[^]i64,n:c.size_t)->i64 {
 context=runtime.default_context()
 if v==nil||n<1||n>16{return -1}
 count:=v[0];if count<0||count>15||n!=c.size_t(count+1){return -1}
 exponent:=i64(0);numerator:=i64(0);packed:=i64(0)
 for i:=i64(0);i<count;i+=1{sample:=v[i+1];if sample < -8||sample>8{return -1};exponent+=1;numerator+=sample*(i64(1)<<u32(exponent-1));signal:=i64(0);if 3*numerator*numerator>((i64(1)<<u32(2*exponent))-1){if numerator>0{signal=1}else{signal=2};exponent=0;numerator=0};packed=packed*4+signal}
 return packed
}
