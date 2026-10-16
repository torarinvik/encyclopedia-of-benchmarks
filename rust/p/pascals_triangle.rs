#[no_mangle]
pub unsafe extern "C" fn pascals_triangle(v:*const i64,n:usize)->i64{if v.is_null()||n!=1{return -1}let rows=*v;if !(1..=31).contains(&rows){return -1}let m=rows as usize;let mut a=[0i64;31];a[0]=1;for r in 1..m{a[r]=1;for j in (1..r).rev(){a[j]+=a[j-1]}}let mut h=0i64;for &x in &a[..m]{h=(h*31+x)%1_000_000_007}h}
