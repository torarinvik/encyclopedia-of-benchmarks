const max_length = 1024
fn ascii_space(c i64) bool { return c==9||c==10||c==11||c==12||c==13||c==32 }
@[export: 'validate_email']
pub fn validate_email(values &i64,length usize) i64 {
	if unsafe { values==nil }||length<2||length>max_length+1 {return -1}
	if unsafe { values[0]<1||values[0]>max_length||usize(values[0])+1!=length } {return -1}
	mut finish:=int(unsafe { values[0] })
	for i in 0 .. finish {c:=unsafe { values[i+1] };if c<0||c>127{return -1}}
	mut at:=finish
	for i in 0 .. finish {c:=unsafe { values[i+1] };if ascii_space(c){return 0};if c==64 {if at!=finish{return 0};at=i}}
	if at==0||at>=finish-1{return 0}
	for i:=at+2;i<finish-1;i++ {if unsafe { values[i+1]==46 } {return 1}}
	return 0
}
