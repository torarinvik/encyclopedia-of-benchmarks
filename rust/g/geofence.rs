const PI_VALUE:f64=3.14159265358979323846264338327950288;
#[no_mangle]
pub extern "C" fn geofence(a:*const i64,n:usize)->i64{
 if a.is_null()||n!=5{return -1}let x=unsafe{std::slice::from_raw_parts(a,n)};
 if x[0]< -90000000||x[0]>90000000||x[2]< -90000000||x[2]>90000000||x[1]< -180000000||x[1]>180000000||x[3]< -180000000||x[3]>180000000||x[4]< -1000000||x[4]>30000000000{return -1}
 let f=PI_VALUE/180000000.0;let lat1=x[0] as f64*f;let lon1=x[1] as f64*f;let lat2=x[2] as f64*f;let lon2=x[3] as f64*f;
 let dl=lat2-lat1;let dg=lon2-lon1;let s1=(dl/2.0).sin();let s2=(dg/2.0).sin();let mut h=s1*s1+lat1.cos()*lat2.cos()*s2*s2;if h<0.0{h=0.0}if h>1.0{h=1.0}
 let distance=6_371_010.0*(2.0*h.sqrt().atan2((1.0-h).sqrt()));(distance<=x[4] as f64/1000.0) as i64
}
