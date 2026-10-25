fn put(out:*mut u8,x:i64){for b in 0..8{unsafe{*out.add(b)=((x as u64)>>(8*b)) as u8;}}}
#[no_mangle]
pub unsafe extern "C" fn mediabench_mpeg2_motion_vector_component(raw:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if raw.is_null()||n!=4{return -1}let v=unsafe{std::slice::from_raw_parts(raw,n)};let pred=v[0];let rs=v[1];let code=v[2];let res=v[3];if !(0..=6).contains(&rs)||!(-16..=16).contains(&code){return -1}let lim=16_i64<<rs;if pred < -lim||pred>=lim{return -1}if (code==0||rs==0){if res!=0{return -1}}else if res<0||res>=(1_i64<<rs){return -1}let mut vec=pred;if code>0{vec+=((code-1)<<rs)+res+1;if vec>=lim{vec-=2*lim}}else if code<0{vec-=((-code-1)<<rs)+res+1;if vec < -lim{vec+=2*lim}}if out.is_null()||cap<8{return -2}put(out,vec);8
}
