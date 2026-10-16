#[no_mangle]
pub unsafe extern "C" fn modular_multiplicative_inverse(v:*const i64,n:usize)->i64{if v.is_null()||n!=2{return -1}let a=*v;let m=*v.add(1);if m<2||m>1_000_000||a<0||a>=m{return -1}let(mut r0,mut r1,mut s0,mut s1)=(a,m,1i64,0i64);while r1!=0{let q=r0/r1;let t=r0-q*r1;r0=r1;r1=t;let t=s0-q*s1;s0=s1;s1=t}if r0==1{(s0%m+m)%m}else{-1}}
