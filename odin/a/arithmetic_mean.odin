package arithmetic_mean
import "core:c"
MAX_LENGTH :: 64
BOUND :: i64(1_000_000)
INVALID_RESULT :: -1.0e300
@(export)
arithmetic_mean :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values==nil || length==0 || length>MAX_LENGTH do return INVALID_RESULT
	total:=i64(0)
	for i:=0;i<int(length);i+=1 { if values[i]<-BOUND || values[i]>BOUND do return INVALID_RESULT; total+=values[i] }
	return f64(total)/f64(length)
}
