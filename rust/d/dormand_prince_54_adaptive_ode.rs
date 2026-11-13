const MAX_INPUT_LENGTH: usize = 7;

fn integer_field(value: f64, low: i64, high: i64) -> Option<i64> {
    if value.is_finite() && value >= low as f64 && value <= high as f64 && value.trunc() == value {
        Some(value as i64)
    } else { None }
}
fn rhs(id: i64, x: f64, y: f64) -> f64 {
    match id { 0 => y, 1 => x+y, 2 => x.sin(), _ => 1.0 }
}
fn trial(id: i64,x: f64,y: f64,h: f64,k1: f64)->Option<(f64,f64,f64)> {
    let k2=rhs(id,x+h*(1.0/5.0),y+h*((1.0/5.0)*k1));
    let k3=rhs(id,x+h*(3.0/10.0),y+h*((3.0/40.0)*k1+(9.0/40.0)*k2));
    let k4=rhs(id,x+h*(4.0/5.0),y+h*((44.0/45.0)*k1-(56.0/15.0)*k2+(32.0/9.0)*k3));
    let k5=rhs(id,x+h*(8.0/9.0),y+h*((19372.0/6561.0)*k1-(25360.0/2187.0)*k2+(64448.0/6561.0)*k3-(212.0/729.0)*k4));
    let k6=rhs(id,x+h,y+h*((9017.0/3168.0)*k1-(355.0/33.0)*k2+(46732.0/5247.0)*k3+(49.0/176.0)*k4-(5103.0/18656.0)*k5));
    let y5=y+h*((35.0/384.0)*k1+(500.0/1113.0)*k3+(125.0/192.0)*k4-(2187.0/6784.0)*k5+(11.0/84.0)*k6);
    let k7=rhs(id,x+h,y5);
    let error=h*((71.0/57600.0)*k1-(71.0/16695.0)*k3+(71.0/1920.0)*k4-(17253.0/339200.0)*k5+(22.0/525.0)*k6-(1.0/40.0)*k7);
    if y5.is_finite()&&error.is_finite()&&k7.is_finite(){Some((y5,error,k7))}else{None}
}
fn integrate(id:i64,mut y:f64,mut x:f64,end:f64,exponent:i64,attempts:i64)->Option<f64>{
    let tolerance=10.0_f64.powf(-(exponent as f64));
    let mut h=((end-x)/4.0).min(0.25);
    let mut k1=rhs(id,x,y);
    for _ in 0..attempts {
        let remaining=end-x;
        if remaining<=0.0{return Some(y)}
        let step=h.min(0.25).min(remaining);
        if step<=0.0||x+step==x{return None}
        let (y5,error,k7)=trial(id,x,y,step,k1)?;
        let scale=tolerance*(1.0+y.abs().max(y5.abs()));
        let norm=error.abs()/scale;
        if !norm.is_finite(){return None}
        if norm<=1.0 { x=if step==remaining{end}else{x+step}; y=y5; k1=k7; if x>=end{return y.is_finite().then_some(y)} }
        let factor=if norm==0.0{5.0}else{0.9*norm.powf(-0.2)};
        h=step*factor.clamp(0.2,5.0);
    }
    None
}

#[no_mangle]
pub unsafe extern "C" fn dormand_prince_54_adaptive_ode(
    input:*const f64,input_length:usize,output:*mut f64,output_capacity:usize)->i64{
    if input.is_null()||input_length!=6||input_length>MAX_INPUT_LENGTH{return -1}
    let values=std::slice::from_raw_parts(input,input_length);
    let Some(id)=integer_field(values[0],0,3) else{return -1};
    let Some(y_milli)=integer_field(values[1],-1000,1000) else{return -1};
    let Some(x_milli)=integer_field(values[2],-1000,1000) else{return -1};
    let Some(end_milli)=integer_field(values[3],-1000,1000) else{return -1};
    let Some(exponent)=integer_field(values[4],8,9) else{return -1};
    let Some(attempts)=integer_field(values[5],64,128) else{return -1};
    if end_milli<=x_milli{return -1}
    if output.is_null()||output_capacity<1{return -2}
    let Some(result)=integrate(id,y_milli as f64/1000.0,x_milli as f64/1000.0,end_milli as f64/1000.0,exponent,attempts) else{return -3};
    if !result.is_finite(){return -3}
    output.write(result);
    1
}
