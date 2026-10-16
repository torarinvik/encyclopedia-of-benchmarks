#[no_mangle]
pub extern "C" fn local_maximum_point(v:*const i64,n:usize)->i64{if v.is_null()||n<1||n>64{return -1;}let a=unsafe{std::slice::from_raw_parts(v,n)};if a.iter().any(|&x|!(-1000000..=1000000).contains(&x)){return -1;}let(mut s,mut e)=(0,n-1);loop{let m=s+(e-s)/2;if (m==0||a[m-1]<=a[m])&&(m==n-1||a[m+1]<=a[m]){return m as i64;}if m>0&&a[m-1]>a[m]{e=m-1;}else{s=m+1;}}}
