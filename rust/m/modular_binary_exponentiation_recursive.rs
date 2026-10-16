fn power(a:i64,e:i64,m:i64)->i64{if e==0{return 1}if e&1==1{return (power(a,e-1,m)*a)%m}let h=power(a,e/2,m);(h*h)%m}
#[no_mangle]
pub unsafe extern "C" fn modular_binary_exponentiation_recursive(v:*const i64,n:usize)->i64{if v.is_null()||n!=3{return -1}let(a,e,m)=(*v,*v.add(1),*v.add(2));if a<0||a>1_000_000||e<0||e>60||m<2||m>1_000_000{return -1}power(a,e,m)}
