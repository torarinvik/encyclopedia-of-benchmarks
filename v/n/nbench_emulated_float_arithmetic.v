module nbench_emulated_float_arithmetic
const max_ops=8
const max_input=1+13*max_ops
struct IFPF {
	typ u8
	sign u8
	exp i16
	mant u64
}
fn sticky_right(mut v IFPF,n int){for _ in 0 .. n{lost:=v.mant&1;v.mant>>=1;if lost!=0{v.mant|=1}}}
fn round_result(mut v IFPF){if v.typ==2{v.mant&=u64(0xfffffffffffffff8)}}
fn normalize(mut v IFPF){for v.mant>>63==0{v.mant<<=1;v.exp--}}
fn add_sub(x0 IFPF,y0 IFPF,op u8) IFPF{
	mut x:=x0;mut y:=y0;mut z:=IFPF{typ:2,sign:x.sign,exp:x.exp,mant:0};d:=int(x.exp)-int(y.exp)
	if d>0{sticky_right(mut y,d)}else if d<0{sticky_right(mut x,-d);z.sign=y.sign^op;z.exp=y.exp}
	if x.sign^y.sign^op!=0{z.mant=x.mant-y.mant;if x.mant<y.mant{z.sign=y.sign^op;z.mant=y.mant-x.mant};if z.mant==0{z.typ=0;z.sign=0;z.exp= -32767}else{normalize(mut z)}}
	else{z.mant=x.mant+y.mant;if z.mant<x.mant{z.exp++;z.mant=(z.mant>>1)|u64(0x8000000000000000)}}
	round_result(mut z);return z
}
fn multiply(x IFPF,y IFPF) IFPF{
	mut z:=IFPF{typ:2,sign:x.sign^y.sign,exp:x.exp+y.exp,mant:0};mut high:=u64(0);mut low:=u64(0);mut mult:=y.mant
	for _ in 0 .. 64{mut carry:=u64(0);if mult&1!=0{old:=high;high+=x.mant;if high<old{carry=1}};mult>>=1;outgoing:=high&1;high=(high>>1)|(carry<<63);low=(low>>1)|(outgoing<<63)}
	for high>>63==0{carry:=low>>63;low<<=1;high=(high<<1)|carry;z.exp--}
	if low==0{high|=1};z.mant=high;round_result(mut z);return z
}
fn divide_emulated(x IFPF,y IFPF) IFPF{
	mut z:=IFPF{typ:2,sign:x.sign^y.sign,exp:x.exp-y.exp+128,mant:0};mut dividend:=x.mant;mut rem:=u64(0)
	for z.mant>>63==0{carry:=dividend>>63;dividend<<=1;overflow:=rem>>63;rem=(rem<<1)|carry;mut bit:=u64(0);if overflow!=0||rem>=y.mant{rem-=y.mant;bit=1};z.mant=(z.mant<<1)|bit;z.exp--}
	round_result(mut z);return z
}
@[export: 'nbench_emulated_float_arithmetic']
pub fn nbench_emulated_float_arithmetic(input &i64,length usize,output &u8,capacity usize)i64{
	unsafe{
		if input==nil||length<14||length>max_input+1{return -1};raw:=input[0];if raw<1||raw>max_ops||length!=usize(1+13*int(raw)){return -1};n:=int(raw);mut results:=[max_ops]IFPF{init:IFPF{}}
		for i in 0 .. n{p:=1+13*i;op:=input[p];sx:=input[p+1];ex:=input[p+2];sy:=input[p+7];ey:=input[p+8];if op<0||op>3||sx<0||sx>1||sy<0||sy>1||ex< -8||ex>8||ey< -8||ey>8{return -1};mut mx:=u64(0);mut my:=u64(0);for j in 0 .. 4{a:=input[p+3+j];b:=input[p+9+j];if a<0||a>65535||b<0||b>65535{return -1};mx=(mx<<16)|u64(a);my=(my<<16)|u64(b)};if mx>>63==0||my>>63==0{return -1};x:=IFPF{typ:2,sign:u8(sx),exp:i16(ex),mant:mx};y:=IFPF{typ:2,sign:u8(sy),exp:i16(ey),mant:my}
			if op==0{results[i]=add_sub(x,y,0)}else if op==1{results[i]=add_sub(x,y,1)}else if op==2{results[i]=multiply(x,y)}else{results[i]=divide_emulated(x,y)}
			r:=results[i];if r.typ==2&&(r.exp< -32||r.exp>32||r.mant>>63==0){return -1}
		}
		bytes:=n*12;if output==nil||capacity<usize(bytes){return -2};for i in 0 .. n{v:=results[i];p:=12*i;output[p]=v.typ;output[p+1]=v.sign;e:=u16(v.exp);output[p+2]=u8(e);output[p+3]=u8(e>>8);for j in 0 .. 4{w:=u16(v.mant>>u64(48-16*j));output[p+4+2*j]=u8(w);output[p+5+2*j]=u8(w>>8)}};return i64(bytes)
	}
}
