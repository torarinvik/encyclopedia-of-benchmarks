const MAX_INPUT_LENGTH: usize = 4096;
#[no_mangle]
pub unsafe extern "C" fn remove_stars(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<1||n>MAX_INPUT_LENGTH+1{return -1;}let a=std::slice::from_raw_parts(v,n);
 if a[0]<0||a[0] as usize>MAX_INPUT_LENGTH||n!=a[0] as usize+1{return -1;}let text=&a[1..];
 let mut result=0usize;for &x in text{if !(0..=127).contains(&x){return -1;}if x==42{result=result.saturating_sub(1)}else{result+=1}}
 if result>cap||(result>0&&out.is_null()){return -2;}let mut w=0usize;for &x in text{if x==42{w=w.saturating_sub(1)}else{*out.add(w)=x as u8;w+=1}}w as i64
}
