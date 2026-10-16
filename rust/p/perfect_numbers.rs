#[no_mangle]
pub unsafe extern "C" fn perfect_numbers(v:*const i64,n:usize)->i64{if v.is_null()||n!=1{return -1}let x=*v;if !(0..=1_000_000_000).contains(&x){return -1}if x<=1{return 0}let mut sum=1i64;let mut d=2i64;while d<=x/d{if x%d==0{sum+=d;if d!=x/d{sum+=x/d}}d+=1}i64::from(sum==x)}
