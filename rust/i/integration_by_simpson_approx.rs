const INVALID:f64=-1.0e300;
fn round_even(x:f64,p:i64)->f64{let mut scale=1.0;for _ in 0..p{scale*=10.0}let y=x*scale;let mut lo=y.floor();let frac=y-lo;if frac>0.5||(frac==0.5&&(lo as i64)%2!=0){lo+=1.0}lo/scale}
#[no_mangle]
pub unsafe extern "C" fn integration_by_simpson_approx(v:*const i64,n:usize)->f64{if v.is_null()||n!=3{return INVALID}let a=*v;let b=*v.add(1);let p=*v.add(2);if a < -10||a>10||b < -10||b>10||a>=b||p<0||p>4{return INVALID}let h=(b-a) as f64/1000.0;let mut result=(a*a) as f64+(b*b) as f64;for i in 1..1000{let x=a as f64+h*i as f64;result+=x*x*if i%2==1{4.0}else{2.0}}result*=h/3.0;round_even(result,p)}
