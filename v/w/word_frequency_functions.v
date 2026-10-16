module word_frequency_functions
import math

const max_term = 128
const max_text = 4096
const max_packed = 4227
const max_count = i64(1000000)

fn wf_punct(c u8) bool { return (c >= 33 && c <= 47) || (c >= 58 && c <= 64) || (c >= 91 && c <= 96) || (c >= 123 && c <= 126) }
fn wf_lower(c u8) u8 { return if c >= 65 && c <= 90 { c + 32 } else { c } }
fn wf_put32(mut output &u8, mut pos int, value u32) { mut bits:=value; for _ in 0 .. 4 { unsafe { output[pos]=u8(bits&255) };pos++;bits>>=8 } }
fn wf_put64(mut output &u8, mut pos int, value i64) { mut bits:=u64(value);for _ in 0 .. 8 { unsafe { output[pos]=u8(bits&255) };pos++;bits>>=8 } }
fn wf_milli(x f64) i64 { y:=x*1000.0;lo:=math.floor(y);f:=y-lo;if f<0.5{return i64(lo)};if f>0.5{return i64(lo+1.0)};k:=i64(lo);return if k%2==0{k}else{k+1} }

@[export: 'word_frequency_functions']
pub fn word_frequency_functions(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if unsafe { input==nil } || length<1 || length>max_packed { return -1 }
	op:=unsafe{input[0]};mut kind:=i64(0);mut a:=i64(0);mut b:=i64(0);mut out_len:=12
	if op==0 || op==1 {
		if length<3 || unsafe{input[1]<0 || input[1]>max_term} { return -1 }
		tn:=int(unsafe{input[1]});ti:=2+tn
		if length<usize(ti+1) || unsafe{input[ti]<0 || input[ti]>max_text} { return -1 }
		dn:=int(unsafe{input[ti]});di:=ti+1;if length!=usize(di+dn){return -1}
		mut term:=[max_term]u8{};mut text:=[max_text]u8{};mut clean:=[max_text]u8{}
		for i in 0 .. tn { v:=unsafe{input[2+i]};if v<0||v>127{return -1};term[i]=wf_lower(u8(v)) }
		for i in 0 .. dn { v:=unsafe{input[di+i]};if v<0||v>127{return -1};text[i]=u8(v) }
		mut cn:=0
		for i in 0 .. dn { if !wf_punct(text[i]) && (op!=0 || text[i]!=10) { clean[cn]=if op==1{wf_lower(text[i])}else{text[i]};cn++ } }
		if op==0 {
			mut start:=0
			for i in 0 .. cn+1 { if i==cn||clean[i]==32 { n:=i-start;mut same:=n==tn;for j in 0 .. n { if same && wf_lower(clean[start+j])!=term[j]{same=false} };if same{a++};start=i+1 } }
		}else{
			kind=1;out_len=20;mut start:=0
			for i in 0 .. cn+1 { if i==cn||clean[i]==10 { n:=i-start;mut found:=tn==0;mut j:=0;for !found&&j+tn<=n { mut k:=0;for k<tn&&clean[start+j+k]==term[k]{k++};if k==tn{found=true};j++ };if found{a++};b++;start=i+1 } }
		}
	}else if op==2 {
		if length!=4{return -1};df:=unsafe{input[1]};n:=unsafe{input[2]};smooth:=unsafe{input[3]}
		if df<0||df>max_count||n<0||n>max_count||(smooth!=0&&smooth!=1){return -1}
		if smooth==1&&n==0{kind=4;out_len=4}else if smooth==0&&df==0{kind=3;out_len=4}else if smooth==0&&n==0{kind=4;out_len=4}else{value:=if smooth==1{1.0+math.log10(f64(n)/f64(1+df))}else{math.log10(f64(n)/f64(df))};kind=2;a=wf_milli(value)}
	}else if op==3 {
		if length!=3{return -1};tf:=unsafe{input[1]};idf:=unsafe{input[2]};if tf<0||tf>max_count||idf< -max_count||idf>max_count{return -1};kind=2;a=tf*idf
	}else{return -1}
	if unsafe{output==nil}||capacity<usize(out_len){return -2}
	mut pos:=0;wf_put32(mut output,mut pos,u32(kind));if kind==0||kind==2{wf_put64(mut output,mut pos,a)}else if kind==1{wf_put64(mut output,mut pos,a);wf_put64(mut output,mut pos,b)}
	return i64(pos)
}
