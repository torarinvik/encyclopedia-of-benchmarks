// Clean-room fixed-rational-scale geometric 2D pattern matching profile.
const MAX_INPUT: usize = 186;
const MAX_FIELDS: usize = 289;
fn put(out: &mut [u8; MAX_FIELDS * 8], at: usize, value: i64) { out[at..at+8].copy_from_slice(&value.to_le_bytes()); }
#[no_mangle]
pub unsafe extern "C" fn two_dimensional_scaled_pattern_matching(v: *const i64,n: usize,out: *mut u8,cap: usize)->i64 {
 if v.is_null()||n<6||n>MAX_INPUT{return -1}let h0=*v;let w0=*v.add(1);let ph0=*v.add(2);let pw0=*v.add(3);let p=*v.add(4);let q=*v.add(5);
 if !(1..=12).contains(&h0)||!(1..=12).contains(&w0)||!(1..=6).contains(&ph0)||!(1..=6).contains(&pw0)||!(1..=8).contains(&q)||p<q||p>2*q{return -1}
 let h=h0 as usize;let w=w0 as usize;let ph=ph0 as usize;let pw=pw0 as usize;if n!=6+h*w+ph*pw{return -1}for i in 0..h*w+ph*pw{let x=*v.add(6+i);if !(0..=255).contains(&x){return -1}}
 let mut fields=[0i64;MAX_FIELDS];let mut count=1usize;
 for r in 0..h{for c in 0..w{if p*ph as i64>q*(h-r)as i64||p*pw as i64>q*(w-c)as i64{continue}let mut matched=true;
  for y in 0..h-r{if (2*y as i64+1)*q>=2*p*ph as i64{continue}let py=((2*y as i64+1)*q/(2*p))as usize;for x in 0..w-c{if (2*x as i64+1)*q>=2*p*pw as i64{continue}let px=((2*x as i64+1)*q/(2*p))as usize;if *v.add(6+(r+y)*w+c+x)!=*v.add(6+h*w+py*pw+px){matched=false;break}}if !matched{break}}
  if matched{fields[count]=r as i64;fields[count+1]=c as i64;count+=2}
 }}fields[0]=((count-1)/2)as i64;let bytes=8*count;if out.is_null()||cap<bytes{return -2}let mut staged=[0u8;MAX_FIELDS*8];for i in 0..count{put(&mut staged,8*i,fields[i])}std::ptr::copy_nonoverlapping(staged.as_ptr(),out,bytes);bytes as i64
}
