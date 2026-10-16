fn mix(h u32, b u8) u32 { return u32((u64(h ^ u32(b)) * u64(16777619)) & u64(0xffffffff)) }
@[export: 'pi_generator']
pub fn pi_generator(digits i64) i64 {
 if digits < 0 || digits > 8 { return -1 }
 mut q:=i64(1); mut r:=i64(0); mut t:=i64(1); mut k:=i64(1); mut n:=i64(3); mut m:=i64(3); mut counter:=i64(0); mut h:=u32(2166136261)
 for counter != digits + 1 {
  if 4*q+r-t < n*t { h=mix(h,u8(48+n)); if counter==0 {h=mix(h,u8(`.`))}; if digits==counter {break}; counter++; nr:=10*(r-n*t); n=(10*(3*q+r))/t-10*n; q*=10; r=nr }
  else { nr:=(2*q+r)*m; nn:=(q*(7*k)+2+r*m)/(t*m); q*=k; t*=m; m+=2; k++; n=nn; r=nr }
 }
 return i64(h)
}
