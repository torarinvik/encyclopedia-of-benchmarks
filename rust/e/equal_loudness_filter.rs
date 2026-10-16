const A:[i64;11]=[1073741824,-3875279605,7242592440,-9849938776,11019995787,-10310050823,8022431451,-5130046574,2558322377,-874363774,153873500];
const B:[i64;11]=[60930872,-44894685,-5549718,-9621322,-7681698,30506759,-32060412,22380311,-4826655,8028337,-4488672];
const HA:[i64;3]=[1089966811,-2146993250,1057516837];
const HB:[i64;3]=[1073619225,-2147238449,1073619225];
fn step(sample:i64,a:&[i64],b:&[i64],x:&mut[i64],y:&mut[i64])->i64{let order=a.len()-1;let mut acc=b[0]*sample;for i in 1..=order{acc+=b[i]*x[i-1]-a[i]*y[i-1]}let out=acc/a[0];for i in (1..order).rev(){x[i]=x[i-1];y[i]=y[i-1]}if order>0{x[0]=sample;y[0]=out}out}
#[no_mangle]
pub extern "C" fn equal_loudness_filter(v:*const i64,n:usize)->i64{if v.is_null()||n<1||n>33{return -1}let s=unsafe{std::slice::from_raw_parts(v,n)};let count=s[0];if !(0..=32).contains(&count)||n!=count as usize+1{return -1}let mut x=[0i64;10];let mut y=[0i64;10];let mut hx=[0i64;2];let mut hy=[0i64;2];let mut out=0;for &sample in &s[1..]{if !(-1_000_000..=1_000_000).contains(&sample){return -1}let mid=step(sample,&A,&B,&mut x,&mut y);out=step(mid,&HA,&HB,&mut hx,&mut hy)}out}
