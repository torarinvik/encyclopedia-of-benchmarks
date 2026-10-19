const MAX_OPS: usize = 8;
const MAX_INPUT: usize = 1 + 13 * MAX_OPS;
#[derive(Clone, Copy)]
struct IFPF { typ:u8, sign:u8, exp:i16, mant:u64 }
fn sticky_right(v:&mut IFPF,n:u32){for _ in 0..n{let lost=v.mant&1;v.mant>>=1;if lost!=0{v.mant|=1;}}}
fn round_result(v:&mut IFPF){if v.typ==2{v.mant&=!7;}}
fn normalize(v:&mut IFPF){while v.mant>>63==0{v.mant<<=1;v.exp-=1;}}
fn add_sub(mut x:IFPF,mut y:IFPF,op:u8)->IFPF{
 let mut z=IFPF{typ:2,sign:x.sign,exp:x.exp,mant:0};let d=i32::from(x.exp)-i32::from(y.exp);
 if d>0{sticky_right(&mut y,d as u32);}else if d<0{sticky_right(&mut x,(-d) as u32);z.sign=y.sign^op;z.exp=y.exp;}
 if x.sign^y.sign^op!=0{z.mant=x.mant.wrapping_sub(y.mant);if x.mant<y.mant{z.sign=y.sign^op;z.mant=y.mant-x.mant;}if z.mant==0{z.typ=0;z.sign=0;}else{normalize(&mut z);}}
 else{z.mant=x.mant.wrapping_add(y.mant);if z.mant<x.mant{z.exp+=1;z.mant=(z.mant>>1)|0x8000_0000_0000_0000;}}
 round_result(&mut z);z
}
fn multiply(x:IFPF,y:IFPF)->IFPF{
 let mut z=IFPF{typ:2,sign:x.sign^y.sign,exp:x.exp+y.exp,mant:0};let(mut high,mut low,mut mult)=(0u64,0u64,y.mant);
 for _ in 0..64{let mut carry=0u64;if mult&1!=0{let old=high;high=high.wrapping_add(x.mant);carry=u64::from(high<old);}mult>>=1;let outgoing=high&1;high=(high>>1)|(carry<<63);low=(low>>1)|(outgoing<<63);}
 while high>>63==0{let carry=low>>63;low<<=1;high=(high<<1)|carry;z.exp-=1;}if low==0{high|=1;}z.mant=high;round_result(&mut z);z
}
fn divide_emulated(x:IFPF,y:IFPF)->IFPF{
 let mut z=IFPF{typ:2,sign:x.sign^y.sign,exp:x.exp-y.exp+128,mant:0};let(mut dividend,mut rem)=(x.mant,0u64);
 while z.mant>>63==0{let carry=dividend>>63;dividend<<=1;let overflow=rem>>63;rem=(rem<<1)|carry;let mut bit=0;if overflow!=0||rem>=y.mant{rem=rem.wrapping_sub(y.mant);bit=1;}z.mant=(z.mant<<1)|bit;z.exp-=1;}round_result(&mut z);z
}
#[no_mangle]
pub unsafe extern "C" fn nbench_emulated_float_arithmetic(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<14||length>MAX_INPUT+1{return -1;}let v=std::slice::from_raw_parts(input,length);let raw=v[0];if raw<1||raw>MAX_OPS as i64||length!=1+13*raw as usize{return -1;}let n=raw as usize;let mut results=[IFPF{typ:0,sign:0,exp:0,mant:0};MAX_OPS];
 for i in 0..n{let p=1+13*i;let(op,sx,ex,sy,ey)=(v[p],v[p+1],v[p+2],v[p+7],v[p+8]);if !(0..=3).contains(&op)||!(0..=1).contains(&sx)||!(0..=1).contains(&sy)||!(-8..=8).contains(&ex)||!(-8..=8).contains(&ey){return -1;}let(mut mx,mut my)=(0u64,0u64);
  for j in 0..4{let(a,b)=(v[p+3+j],v[p+9+j]);if !(0..=65535).contains(&a)||!(0..=65535).contains(&b){return -1;}mx=(mx<<16)|a as u64;my=(my<<16)|b as u64;}if mx>>63==0||my>>63==0{return -1;}let x=IFPF{typ:2,sign:sx as u8,exp:ex as i16,mant:mx};let y=IFPF{typ:2,sign:sy as u8,exp:ey as i16,mant:my};
  results[i]=match op{0=>add_sub(x,y,0),1=>add_sub(x,y,1),2=>multiply(x,y),_=>divide_emulated(x,y)};let r=results[i];if r.typ==2&&(!(-80..=32).contains(&r.exp)||r.mant>>63==0){return -1;}
 }
 let bytes=n*12;if output.is_null()||capacity<bytes{return -2;}for i in 0..n{let r=results[i];let p=12*i;*output.add(p)=r.typ;*output.add(p+1)=r.sign;let e=r.exp as u16;*output.add(p+2)=e as u8;*output.add(p+3)=(e>>8) as u8;for j in 0..4{let w=(r.mant>>(48-16*j)) as u16;*output.add(p+4+2*j)=w as u8;*output.add(p+5+2*j)=(w>>8) as u8;}}bytes as i64
}
