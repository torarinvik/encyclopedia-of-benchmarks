#[no_mangle]
pub extern "C" fn kinematics(v:*const i64,n:usize)->i64{if v.is_null()||n!=4{return -1;}let a=unsafe{std::slice::from_raw_parts(v,4)};let(o,x,y,z)=(a[0],a[1],a[2],a[3]);if !(0..=3).contains(&o)||[x,y,z].iter().any(|q|q.abs()>1000){return -1;}match o{0=>2*x+2*y*z,1=>2*x*z+y*z*z,2=>2*x*x+4*y*z,_=>(x+y)*z}}
