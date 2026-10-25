fn f32round(x:f64)->f32{x as f32}
#[no_mangle]
pub unsafe extern "C" fn cbench_rsynth_impulsive_glottal_sample(input:*const f64,n:usize,output:*mut f64,cap:usize)->i64{
 if input.is_null()||n==0||n>3{return -1}let a=std::slice::from_raw_parts(input,n);if a.iter().any(|x|!x.is_finite()){return -1}
 if n!=2||a[0]<40.0||a[0]>263.0||a[0].trunc()!=a[0]||a[1]<0.0||a[1]>299.0||a[1].trunc()!=a[1]{return -1}
 let open=a[0] as i64;let target=a[1] as i64;let rate=8000i64;
 let minus_pi=f32round(-std::f64::consts::PI/rate as f64);let two_pi=f32round(-2.0*minus_pi as f64);let bw=rate/open;
 let r=f32round((minus_pi as f64*bw as f64).exp());let c=-(r*r);let b=f32round(r as f64*(two_pi as f64*0.0).cos()*2.0);
 let mut aa=f32round(1.0-b as f64-c as f64);let t=f32round(open as f64*0.00833);aa=f32round(aa*(t*t));
 let(mut p1,mut p2,mut result)=(0.0f32,0.0f32,0.0f32);
 for i in 0..=target{let impulse=match i{0=>0.0,1=>13_000_000.0,2=>-13_000_000.0,_=>0.0};let mut x=f32round(aa*impulse);x=f32round(x+f32round(b*p1));x=f32round(x+f32round(c*p2));p2=p1;p1=x;result=x;}
 if output.is_null()||cap<1{return -2}*output=result as f64;1
}
