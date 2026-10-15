package hill_cipher_mod36

import "core:c"

symbol_value :: proc(value: i64) -> int {
	code := value
	if code >= i64('a') && code <= i64('z') { code -= i64('a'-'A') }
	if code >= i64('A') && code <= i64('Z') { return int(code-i64('A')) }
	if code >= i64('0') && code <= i64('9') { return int(code-i64('0'))+26 }
	return -1
}
output_symbol :: proc(value: int) -> u8 { if value<26{return u8('A'+value)};return u8('0'+value-26) }

@(export)
hill_cipher_mod36 :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<3 || input[0]<0 || input[0]>1 do return -1
	raw_length:=input[1];if raw_length<1||raw_length>256||length!=c.size_t(raw_length+2) do return -1
	var text:[256]int;count:=0
	for i:=0;i<int(raw_length);i+=1 { byte:=input[2+i];if byte<0||byte>127 do return -1;value:=symbol_value(byte);if value>=0{text[count]=value;count+=1} }
	if count==0 do return -1
	if count%2!=0{text[count]=text[count-1];count+=1}
	if output==nil||capacity<c.size_t(count) do return -2
	decrypt:=input[0]==1
	for i:=0;i<count;i+=2 { a,b:=text[i],text[i+1];first,second:=0,0
		if decrypt{first=(6*a+25*b)%36;second=(5*a+26*b)%36}else{first=(2*a+5*b)%36;second=(a+6*b)%36}
		output[i]=output_symbol(first);output[i+1]=output_symbol(second)
	}
	return i64(count)
}
