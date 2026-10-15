package validate_email
import "core:c"
MAX_LENGTH :: 1024
ascii_space :: proc "contextless" (c:i64)->bool{return c==9||c==10||c==11||c==12||c==13||c==32}
@(export)
validate_email :: proc "c" (v:[^]i64,n:c.size_t)->i64 {
	if v==nil||n<2||n>MAX_LENGTH+1||v[0]<1||v[0]>MAX_LENGTH||int(v[0])+1!=int(n) do return -1
	finish:=int(v[0]);for i in 0..<finish {if v[i+1]<0||v[i+1]>127 do return -1}
	at:=finish
	for i in 0..<finish {c:=v[i+1];if ascii_space(c) do return 0;if c==64 {if at!=finish do return 0;at=i}}
	if at==0||at>=finish-1 do return 0
	for i:=at+2;i<finish-1;i+=1 {if v[i+1]==46 do return 1}
	return 0
}
