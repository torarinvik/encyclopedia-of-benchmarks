const INVALID_RESULT: f64 = -1.0e300;
const MAX_SAMPLES: usize = 16;
#[no_mangle]
pub extern "C" fn gradient_boosting_regressor(v: *const i64, len: usize) -> f64 {
    if v.is_null() || len < 8 || len > 36 { return INVALID_RESULT; }
    let a = unsafe { std::slice::from_raw_parts(v, len) };
    let (n0, rounds, rate0, query) = (a[0], a[1], a[2], a[3]);
    if n0 < 2 || n0 > MAX_SAMPLES as i64 || rounds < 1 || rounds > 12 || rate0 < 1 || rate0 > 1_000_000 || len != 4+2*n0 as usize { return INVALID_RESULT; }
    let n=n0 as usize;let mut x=[0.0f64;MAX_SAMPLES];let mut y=[0.0f64;MAX_SAMPLES];let mut pred=[0.0f64;MAX_SAMPLES];let mut residual=[0.0f64;MAX_SAMPLES];
    for i in 0..n {let xi=a[4+i];let yi=a[4+n+i];if !(-1000..=1000).contains(&xi)||!(-1_000_000..=1_000_000).contains(&yi)||(i>0&&a[3+i]>=xi){return INVALID_RESULT;}x[i]=xi as f64;y[i]=yi as f64/1000.0;}
    if !(-1000..=1000).contains(&query){return INVALID_RESULT;}
    let mean=y[..n].iter().sum::<f64>()/n as f64;for i in 0..n{pred[i]=mean;}let mut qpred=mean;let rate=rate0 as f64/1_000_000.0;
    for _ in 0..rounds {let mut sum=0.0;for i in 0..n{residual[i]=y[i]-pred[i];sum+=residual[i];}let constant=residual[1..n].iter().all(|z|*z==residual[0]);let mut best=1e300;let mut split=n;let(mut left,mut right)=(0.0,0.0);
        if !constant {for s in 0..n-1 {let nl=s+1;let sl=residual[..nl].iter().sum::<f64>();let sr=residual[nl..n].iter().sum::<f64>();let lm=sl/nl as f64;let rm=sr/(n-nl) as f64;let err=residual[..nl].iter().map(|z|(z-lm)*(z-lm)).sum::<f64>()+residual[nl..n].iter().map(|z|(z-rm)*(z-rm)).sum::<f64>();if err<best{best=err;split=s;left=lm;right=rm;}}}
        if split==n {let leaf=sum/n as f64;for i in 0..n{pred[i]+=rate*leaf;}qpred+=rate*leaf;}else{let t=(x[split]+x[split+1])/2.0;for i in 0..n{pred[i]+=rate*if x[i]<=t{left}else{right};}qpred+=rate*if (query as f64)<=t{left}else{right};}
    }qpred
}
