const EPSILON:f64=1.0e-7;
const MIN_WIDTH:f64=2.0e-7;
fn objective(id:i32,x:f64)->f64{if id==0{(x-2.0)*(x-2.0)}else{x.cos()}}
/// Golden-section minimizer for two bounded deterministic objectives.
#[no_mangle]
pub extern "C" fn golden_search_extrema(objective_id:f64,left:f64,right:f64)->f64{
    if objective_id!=0.0&&objective_id!=1.0{return -1.0;}
    if objective_id==0.0&&(!(left>=0.0&&left<=4.0)||!(right>=0.0&&right<=4.0)){return -1.0;}
    if objective_id==1.0&&(!(left>=2.0&&left<=4.0)||!(right>=2.0&&right<=4.0)){return -1.0;}
    let(mut a,mut b)=(left,right);if a>b{std::mem::swap(&mut a,&mut b);}
    let extremum=if objective_id==0.0{2.0}else{std::f64::consts::PI};
    if b-a<MIN_WIDTH||!(a<extremum&&extremum<b){return -1.0;}
    let id=objective_id as i32;let mut mean=f64::INFINITY;let mut previous_mean=f64::INFINITY;let phi=1.61803400516510009765625;
    for _ in 0..128{if (b-a).abs()<=EPSILON{break;}previous_mean=mean;let ratio=(b-a)/phi;let c=b-ratio;let d=a+ratio;if objective(id,c)<objective(id,d){b=d;}else{a=c;}mean=(a+b)/2.0;}
    previous_mean
}
