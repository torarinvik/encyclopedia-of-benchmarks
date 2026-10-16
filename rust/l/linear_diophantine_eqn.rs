#[no_mangle]
pub extern "C" fn linear_diophantine_eqn(v:*const i64,n:usize)->i64{if v.is_null()||n!=3{return -1;}let x=unsafe{std::slice::from_raw_parts(v,3)};let(a,b,c)=(x[0],x[1],x[2]);if !(-100000..=100000).contains(&a)||b==0||!(-100000..=100000).contains(&b)||!(-1000000..=1000000).contains(&c){return -1;}let g=gcd(a.abs(),b.abs());if c%g==0{1}else{0}}
fn gcd(mut a:i64,mut b:i64)->i64{while b!=0{let r=a%b;a=b;b=r;}a}
