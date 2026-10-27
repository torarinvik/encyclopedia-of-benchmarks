module felsenstein_substitution_likelihood

fn put_i64(mut output &u8, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'felsenstein_substitution_likelihood']
pub fn felsenstein_substitution_likelihood(input &i64,length usize,mut output &u8,capacity usize)i64{
	if input==nil||length<3||length>38{return -1}
	unsafe{
		n:=input[0];if n<1||n>8{return -1}
		mut stack:=[8][2]i64{};mut sp:=0;mut leaves:=i64(0);mut joins:=i64(0);mut edges:=i64(0);mut at:=1
		for at<int(length){tag:=input[at];at++;if tag==0{if at>=int(length)||input[at]<0||input[at]>1||sp>=8{return -1};if input[at]==0{stack[sp]=[2]i64{1,0}}else{stack[sp]=[2]i64{0,1}};at++;sp++;leaves++}else if tag==1{if at+2>int(length)||sp<2||input[at]<0||input[at]>1||input[at+1]<0||input[at+1]>1{return -1};lm:=input[at];rm:=input[at+1];at+=2;left:=stack[sp-2];right:=stack[sp-1];mut next:=[2]i64{};for parent in 0..2{mut l:=left[parent];mut r:=right[parent];if lm==0{l*=4}else{l=3*l+left[1-parent]};if rm==0{r*=4}else{r=3*r+right[1-parent]};next[parent]=l*r};stack[sp-2]=next;sp--;joins++;edges+=2}else{return -1}}
		if leaves!=n||joins!=n-1||sp!=1||edges!=2*n-2{return -1};shift:=29-2*edges;if shift<0{return -1};scaled:=(stack[0][0]+stack[0][1])<<shift
		if output==nil||capacity<8{return -2};put_i64(mut output,scaled);return 8
	}
}
