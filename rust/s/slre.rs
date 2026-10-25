// SPDX-License-Identifier: GPL-3.0-or-later
// Bounded modified profile of Embench slre; see package NOTICE.txt for upstream attribution.
fn atom(x:i64)->bool{(b'a' as i64..=b'z' as i64).contains(&x)||x==b'.' as i64}
#[no_mangle] pub extern "C" fn slre(raw:*const i64,n:usize)->i64{
 if n<2{return -2} let v=unsafe{std::slice::from_raw_parts(raw,n)};if !(0..=24).contains(&v[0])||!(1..=24).contains(&v[1]){return -2}
 let(t,p)=(v[0] as usize,v[1] as usize);let ps=2+t;if n!=ps+p{return -2}if v[2..ps].iter().any(|&x|x<b'a' as i64||x>b'z' as i64){return -2}
 let(mut lo,mut hi)=(0,p);let mut ast=false;let mut aend=false;if v[ps]==b'^' as i64{ast=true;lo+=1}if lo<hi&&v[ps+hi-1]==b'$' as i64{aend=true;hi-=1}
 let(mut i,mut non)=(lo,false);while i<hi{let x=v[ps+i];if x==b'|' as i64{if !non{return -2}non=false;i+=1;continue}if !atom(x){return -2}non=true;i+=1;if i<hi&&v[ps+i]==b'?' as i64{i+=1}}if !non{return -2}
 for start in 0..=t{if ast&&start>0{break}let mut b=lo;while b<=hi{let mut e=b;while e<hi&&v[ps+e]!=b'|' as i64{e+=1;if e<hi&&v[ps+e]==b'?' as i64{e+=1}}let(mut q,mut pos,mut ok)=(b,start,true);while q<e{let x=v[ps+q];let opt=q+1<e&&v[ps+q+1]==b'?' as i64;if pos<t&&(x==b'.' as i64||x==v[2+pos]){pos+=1}else if !opt{ok=false;break}q+=if opt{2}else{1}}if ok&&(!aend||pos==t){return pos as i64}if e==hi{break}b=e+1}}
 -1
}
