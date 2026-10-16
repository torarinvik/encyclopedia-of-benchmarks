const CRITICAL: [f64; 9] = [0.0,0.0,0.0,1.1543048513440384,1.48125,1.715037312343363,1.887145117783933,2.0199685076795957,2.126645087195462];
#[no_mangle]
pub unsafe extern "C" fn generalized_esd(v: *const i64, length: usize) -> i64 {
 if v.is_null() || length < 5 { return -1; }
 let a=std::slice::from_raw_parts(v,length);let n=a[0];let limit=a[1];
 if !(3..=8).contains(&n)||!(1..=3).contains(&limit)||limit>n-2||length!=n as usize+2{return -1;}
 let mut x=[0.0f64;8];let mut idx=[0usize;8];for i in 0..n as usize{if !(-10000..=10000).contains(&a[i+2]){return -1;}x[i]=a[i+2] as f64;idx[i]=i;}
 let mut remaining=n as usize;let mut accepted=0usize;let mut removed=[0usize;3];
 for step in 1..=limit as usize{let mut mean=0.0;for i in 0..remaining{mean+=x[i];}mean/=remaining as f64;let mut ss=0.0;for i in 0..remaining{let d=x[i]-mean;ss+=d*d;}let sd=(ss/(remaining-1) as f64).sqrt();if sd==0.0{break;}let mut worst=0;let mut largest=-1.0;for i in 0..remaining{let d=(x[i]-mean).abs();if d>largest{largest=d;worst=i;}}removed[step-1]=idx[worst];if largest/sd>CRITICAL[remaining]{accepted=step;}remaining-=1;x[worst]=x[remaining];idx[worst]=idx[remaining];}
 let mut mask=0i64;for i in 0..accepted{mask|=1i64<<removed[i];}mask
}
