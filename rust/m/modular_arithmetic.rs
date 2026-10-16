#[no_mangle]
pub unsafe extern "C" fn modular_arithmetic(v:*const i64,n:usize)->i64{
 if v.is_null()||n!=4{return -1}let x=std::slice::from_raw_parts(v,n);let(op,m,a,b)=(x[0],x[1],x[2],x[3]);
 if !(0..=2).contains(&op)||!(1..=1_000_000).contains(&m)||a<0||a>=m||b<0||b>=m{return -1}
 match op{0=>((a%m)+(b%m))%m,1=>((a%m)-(b%m)+m)%m,_=>((a%m)*(b%m))%m}
}
