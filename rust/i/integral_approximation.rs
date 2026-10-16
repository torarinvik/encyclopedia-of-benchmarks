const INVALID:f64=-1.0e300;
fn f(id:i64,x:f64)->f64{if id==0{x*x}else{x*x*x-x*x+378.0}}
#[no_mangle]
pub unsafe extern "C" fn integral_approximation(v:*const i64,n:usize)->f64{if v.is_null()||n!=4{return INVALID}let a=std::slice::from_raw_parts(v,4);let(id,li,ui,di)=(a[0],a[1],a[2],a[3]);if id<0||id>1||li<0||ui>32||li>=ui||di<1||di>8{return INVALID}let lo=li as f64/8.0;let hi=ui as f64/8.0;let d=di as f64/8.0;let count=((hi-lo)/d) as u64;if count>32{return INVALID}let mut total=0.0;for i in 0..count{let begin=lo+i as f64*d;let end=lo+(i+1) as f64*d;total+=d*(f(id,begin)+f(id,end))/2.0;}total}
