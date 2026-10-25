#[no_mangle]
pub unsafe extern "C" fn cbench_rsynth_f0_flutter(input:*const i64,n:usize)->i64{
 if input.is_null()||n==0||n>4{return -1}let a=std::slice::from_raw_parts(input,n);
 if n!=3||a[0]<0||a[0]>20000||a[1]<0||a[1]>100||a[2]<0||a[2]>1_000_000{return -1}
 let f0=a[0];let flutter=a[1];let t=a[2];let original=f0/10;let pi=3.1415927f64;
 let fla=flutter as f64/50.0;let flb=original as f64/100.0;
 let flc=(2.0*pi*12.7*t as f64).sin();let fld=(2.0*pi*7.1*t as f64).sin();let fle=(2.0*pi*4.7*t as f64).sin();
 let delta=fla*flb*(flc+fld+fle)*10.0;f0+delta.trunc() as i64
}
