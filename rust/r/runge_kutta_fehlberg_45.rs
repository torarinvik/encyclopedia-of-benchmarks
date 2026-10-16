const INVALID: f64 = -1.0e300;
fn f(id:i64,x:f64,y:f64)->f64{match id{0=>y,1=>x,2=>x+y,3=>(x-y)/2.0,_=>1.0+y*y}}
fn step(id:i64,x:f64,y:f64,h:f64)->Option<f64>{
    let k1=h*f(id,x,y);let k2=h*f(id,x+h/4.0,y+k1/4.0);let k3=h*f(id,x+(3.0/8.0)*h,y+(3.0/32.0)*k1+(9.0/32.0)*k2);
    let k4=h*f(id,x+(12.0/13.0)*h,y+(1932.0/2197.0)*k1-(7200.0/2197.0)*k2+(7296.0/2197.0)*k3);
    let k5=h*f(id,x+h,y+(439.0/216.0)*k1-8.0*k2+(3680.0/513.0)*k3-(845.0/4104.0)*k4);
    let k6=h*f(id,x+h/2.0,y-(8.0/27.0)*k1+2.0*k2-(3544.0/2565.0)*k3+(1859.0/4104.0)*k4-(11.0/40.0)*k5);
    let out=y+(16.0/135.0)*k1+(6656.0/12825.0)*k3+(28561.0/56430.0)*k4-(9.0/50.0)*k5+(2.0/55.0)*k6;
    if [k1,k2,k3,k4,k5,k6,out].iter().all(|v|v.is_finite()){Some(out)}else{None}
}
#[no_mangle]
pub unsafe extern "C" fn runge_kutta_fehlberg_45(input:*const i64,length:usize)->f64{
    if input.is_null()||length!=5{return INVALID}let v=std::slice::from_raw_parts(input,length);let(id,ym,xm,hm,em)=(v[0],v[1],v[2],v[3],v[4]);
    if !(0..=4).contains(&id)||!(-1_000_000..=1_000_000).contains(&ym)||!(-1_000_000..=1_000_000).contains(&xm)||!(-1_000_000..=1_000_000).contains(&em)||!(10_000..=250_000).contains(&hm)||em<=xm{return INVALID}
    let(mut y,mut x,h,end)=(ym as f64/1_000_000.0,xm as f64/1_000_000.0,hm as f64/1_000_000.0,em as f64/1_000_000.0);
    if id==4&&(x<0.0||y>0.0){return INVALID}let steps=((end-x)/h) as usize;if !(1..=64).contains(&steps){return INVALID}
    for _ in 0..steps{y=match step(id,x,y,h){Some(value)=>value,None=>return INVALID};x=h+x;if !x.is_finite(){return INVALID}}
    y
}
