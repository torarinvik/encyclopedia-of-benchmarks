const INVALID: f64 = -1.0e300;
fn f(id:i64,x:f64,y:f64)->f64{match id{0=>y,1=>x,2=>x+y,3=>(x-y)/2.0,_=>1.0+y*y}}
fn step(id:i64,x:f64,y:f64,h:f64)->Option<f64>{
    let k1=f(id,x,y);let k2=f(id,x+0.5*h,y+0.5*h*k1);let k3=f(id,x+0.5*h,y+0.5*h*k2);let k4=f(id,x+h,y+h*k3);
    let out=y+(1.0/6.0)*h*(k1+2.0*k2+2.0*k3+k4);
    if [k1,k2,k3,k4,out].iter().all(|v|v.is_finite()){Some(out)}else{None}
}
#[no_mangle]
pub unsafe extern "C" fn runge_kutta(input:*const i64,length:usize)->f64{
    if input.is_null()||length!=5{return INVALID}let v=std::slice::from_raw_parts(input,length);
    let(id,ym,xm,hm,em)=(v[0],v[1],v[2],v[3],v[4]);
    if !(0..=4).contains(&id)||!(-1_000_000..=1_000_000).contains(&ym)||!(-1_000_000..=1_000_000).contains(&xm)||!(-1_000_000..=1_000_000).contains(&em)||!(10_000..=250_000).contains(&hm)||em<=xm{return INVALID}
    let(mut y,mut x,h,end)=(ym as f64/1_000_000.0,xm as f64/1_000_000.0,hm as f64/1_000_000.0,em as f64/1_000_000.0);
    if id==4&&(x<0.0||y>0.0){return INVALID}let steps=((end-x)/h).ceil() as usize;if !(1..=64).contains(&steps){return INVALID}
    for _ in 0..steps{y=match step(id,x,y,h){Some(value)=>value,None=>return INVALID};x+=h;if !x.is_finite(){return INVALID}}
    y
}
