package hill_cipher_mod26_java

import "core:c"

@(export)
hill_cipher_mod26_java :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<1 || length>257 do return -1
	if input[0]!=0 && input[0]!=1 do return -1
	key: [4]i64
	if input[0]==0 { key=[4]i64{3,3,2,5} } else { key=[4]i64{15,17,20,9} }
	var text:[256]u8
	text_length:=0
	for i:usize=1;i<usize(length);i+=1 {
		if input[i]<0 || input[i]>127 do return -1
		cbyte:=u8(input[i]);if cbyte>='a'&&cbyte<='z' { cbyte=cbyte-'a'+'A' };if cbyte>='A'&&cbyte<='Z' { text[text_length]=cbyte;text_length+=1 }
	}
	if text_length%2==1 { text[text_length]='X';text_length+=1 }
	if c.size_t(text_length)>capacity || (text_length>0&&output==nil) do return -2
	for i:usize=0;i<text_length;i+=2 { a:=i64(text[i]-'A');b:=i64(text[i+1]-'A');output[i]=u8(i64('A')+(key[0]*a+key[1]*b)%26);output[i+1]=u8(i64('A')+(key[2]*a+key[3]*b)%26) }
	return i64(text_length)
}
