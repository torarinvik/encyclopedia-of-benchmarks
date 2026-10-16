fn peak(a:&[i64],lo:isize,hi:isize,n:isize)->i64{let mid=lo+(hi-lo)/2;if((mid==0||a[(mid-1)as usize]<=a[mid as usize])&&(mid==n-1||a[(mid+1)as usize]<=a[mid as usize])){return mid as i64}if mid>0&&a[(mid-1)as usize]>a[mid as usize]{peak(a,lo,mid-1,n)}else{peak(a,mid+1,hi,n)}}
#[no_mangle]
pub unsafe extern "C" fn peak_element(v:*const i64,n:usize)->i64{if v.is_null()||n<2||n>129{return -1}let a=std::slice::from_raw_parts(v,n);if a[0]<1||a[0]>128||n!=a[0]as usize+1||a[1..].iter().any(|&x|x<i32::MIN as i64||x>i32::MAX as i64){return -1}peak(&a[1..],0,a[0]as isize-1,a[0]as isize)}
