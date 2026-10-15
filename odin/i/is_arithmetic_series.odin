package is_arithmetic_series
import "core:c"
MAX_LENGTH :: 64
BOUND :: i64(1_000_000)
@(export)
is_arithmetic_series :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values==nil || length==0 || length>MAX_LENGTH do return -1
	for i:=0;i<int(length);i+=1 { if values[i]<-BOUND || values[i]>BOUND do return -1 }
	if length==1 do return 1
	difference:=values[1]-values[0]
	for i:=1;i+1<int(length);i+=1 { if values[i+1]-values[i]!=difference do return 0 }
	return 1
}
