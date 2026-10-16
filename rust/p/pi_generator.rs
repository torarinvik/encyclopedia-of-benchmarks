fn mix(h:u32,b:u8)->u32{(h^u32::from(b)).wrapping_mul(16_777_619)}
#[no_mangle]
pub extern "C" fn pi_generator(digits:i64)->i64{if !(0..=8).contains(&digits){return -1}let(mut q,mut r,mut t,mut k,mut n,mut m,mut counter)=(1i64,0i64,1i64,1i64,3i64,3i64,0i64);let mut h=2_166_136_261u32;while counter!=digits+1{if 4*q+r-t<n*t{h=mix(h,(48+n)as u8);if counter==0{h=mix(h,b'.')}if digits==counter{break}counter+=1;let nr=10*(r-n*t);n=(10*(3*q+r))/t-10*n;q*=10;r=nr;}else{let nr=(2*q+r)*m;let nn=(q*(7*k)+2+r*m)/(t*m);q*=k;t*=m;m+=2;k+=1;n=nn;r=nr;}}i64::from(h)}
