#[no_mangle]
pub extern "C" fn largest_divisible_subset(v:*const i64,n:usize)->i64{if (v.is_null()&&n!=0)||n>64{return -1;}let mut a=if n==0{Vec::new()}else{unsafe{std::slice::from_raw_parts(v,n)}.to_vec()};if a.iter().any(|&x|x<1||x>50000){return -1;}a.sort();let mut d=vec![1i64;n];let mut best=0;for i in 0..n{for j in 0..i{if a[i]%a[j]==0{d[i]=d[i].max(d[j]+1);}}best=best.max(d[i]);}best}
