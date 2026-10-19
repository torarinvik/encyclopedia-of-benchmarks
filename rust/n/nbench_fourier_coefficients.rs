const MAX_N: usize = 16;
const INVALID: f64 = -1e300;
fn term(x:f64,omega:f64,select:usize)->f64{let base=(x+1.0).powf(x);if select==0{base}else if select==1{base*(omega*x).cos()}else{base*(omega*x).sin()}}
fn integrate(omega:f64,select:usize)->f64{let mut x=0.0;let dx=(2.0-0.0)/200.0;let mut value=term(0.0,omega,select)/2.0;let mut steps=200;if steps!=1{steps-=1;loop{steps-=1;if steps==0{break;}x+=dx;value+=term(x,omega,select);}}(value+term(2.0,omega,select)/2.0)*dx}
#[no_mangle]
pub unsafe extern "C" fn nbench_fourier_coefficients(input:*const i64,length:usize)->f64{if input.is_null()||length<1||length>2{return INVALID;}let v=std::slice::from_raw_parts(input,length);if v[0]<1||v[0]>MAX_N as i64||length!=1{return INVALID;}let n=v[0] as usize;let mut a=[0.0;MAX_N];let mut b=[0.0;MAX_N];a[0]=integrate(0.0,0)/2.0;for i in 1..n{let omega=3.1415926535897932*i as f64;a[i]=integrate(omega,1);b[i]=integrate(omega,2);}let mut checksum=0.0;for i in 0..n{checksum+=(i+1) as f64*a[i];}for i in 1..n{checksum+=i as f64*b[i];}if checksum.is_finite(){checksum}else{INVALID}}
