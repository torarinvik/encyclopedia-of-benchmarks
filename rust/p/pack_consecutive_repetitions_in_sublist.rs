fn mix(h:u32,b:u8)->u32{(h^u32::from(b)).wrapping_mul(16_777_619)}
fn feed(mut h:u32,x:u32)->u32{for s in [0,8,16,24]{h=mix(h,(x>>s) as u8)}h}
#[no_mangle]
pub unsafe extern "C" fn pack_consecutive_repetitions_in_sublist(v:*const i64,n:usize)->i64{
 if v.is_null()||n<1||n>65{return -1}let a=std::slice::from_raw_parts(v,n);if !(0..=64).contains(&a[0])||n!=a[0] as usize+1{return -1}let count=a[0] as usize;
 if a[1..].iter().any(|x|*x<i32::MIN as i64||*x>i32::MAX as i64){return -1}
 let mut h=2_166_136_261u32;let mut i=0;while i<count{let value=a[i+1] as i32;let mut j=i+1;while j<count&&a[j+1]==i64::from(value){j+=1}h=feed(h,value as u32);h=feed(h,(j-i) as u32);i=j;}i64::from(h)
}
