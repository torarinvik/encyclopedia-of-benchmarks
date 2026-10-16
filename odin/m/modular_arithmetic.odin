package modular_arithmetic
import "core:c"
@(export)
modular_arithmetic :: proc "c" (values:[^]i64,length:c.size_t)->i64 {
	if values==nil||length!=4 do return -1
	op:=values[0];m:=values[1];a:=values[2];b:=values[3]
	if op<0||op>2||m<1||m>1_000_000||a<0||a>=m||b<0||b>=m do return -1
	if op==0 do return ((a%m)+(b%m))%m
	if op==1 do return ((a%m)-(b%m)+m)%m
	return ((a%m)*(b%m))%m
}
