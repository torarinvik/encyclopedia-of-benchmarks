module hill_cipher_mod26_java

@[export: 'hill_cipher_mod26_java']
pub fn hill_cipher_mod26_java(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input==nil } || length<1 || length>257 { return -1 }
	unsafe {
		if input[0]!=0 && input[0]!=1 { return -1 }
		key:=if input[0]==0 { [4]i64{3,3,2,5} } else { [4]i64{15,17,20,9} }
		mut text:=[256]u8{};mut text_len:=0
		for i in 1 .. int(length) {
			if input[i]<0 || input[i]>127 { return -1 }
			mut c:=u8(input[i]);if c>='a'&&c<='z' { c=c-'a'+'A' };if c>='A'&&c<='Z' { text[text_len]=c;text_len++ }
		}
		if text_len%2==1 { text[text_len]=u8('X');text_len++ }
		if text_len>capacity || (text_len>0 && unsafe { output==nil }) { return -2 }
		for i in 0 .. text_len/2 { offset:=2*i;a:=i64(text[offset]-u8('A'));b:=i64(text[offset+1]-u8('A'));unsafe { output[offset]=u8(i64('A')+(key[0]*a+key[1]*b)%26);output[offset+1]=u8(i64('A')+(key[2]*a+key[3]*b)%26) } }
		return i64(text_len)
	}
}
