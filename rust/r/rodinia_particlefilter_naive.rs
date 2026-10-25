// Rodinia particlefilter_naive one-transition profile; full notice: benchmarks/r/rodinia_particlefilter_naive/LICENSE.txt.
const SCALE:f64=1_000_000.0;
fn round_away(value:f64)->i64{let scaled=value*1000.0;if scaled<0.0{-((-scaled+0.5).floor() as i64)}else{(scaled+0.5).floor() as i64}}

#[no_mangle]
pub unsafe extern "C" fn rodinia_particlefilter_naive(input:*const i64,length:usize)->i64{
    if input.is_null()||length<8||length>35{return -1;}
    let v=unsafe{std::slice::from_raw_parts(input,length)};let (n_raw,samples_raw,offset_raw)=(v[0],v[1],v[2]);
    if n_raw<1||n_raw>4||samples_raw<1||samples_raw>4{return -1;}
    let (n,samples)=(n_raw as usize,samples_raw as usize);
    if length!=3+n*(4+samples)||offset_raw<0||offset_raw>=1_000_000||offset_raw*n_raw>=1_000_000{return -1;}
    let mut x=[0.0;4];let mut y=[0.0;4];let mut moved_x=[0.0;4];let mut moved_y=[0.0;4];let mut weights=[0.0;4];let mut cdf=[0.0;4];let mut resampled_x=[0.0;4];let mut resampled_y=[0.0;4];
    for i in 0..n{
        let at=3+i*(4+samples);let (xr,yr,nxr,nyr)=(v[at],v[at+1],v[at+2],v[at+3]);
        if !(-100_000_000..=100_000_000).contains(&xr)||!(-100_000_000..=100_000_000).contains(&yr)||!(-2_000_000..=2_000_000).contains(&nxr)||!(-2_000_000..=2_000_000).contains(&nyr){return -1;}
        x[i]=xr as f64/SCALE;y[i]=yr as f64/SCALE;moved_x[i]=x[i]+1.0+5.0*(nxr as f64/SCALE);moved_y[i]=y[i]-2.0+2.0*(nyr as f64/SCALE);
        let mut likelihood_sum=0.0;
        for j in 0..samples{let intensity=v[at+4+j];if !(0..=255).contains(&intensity){return -1;}let foreground=(intensity-100) as f64;let background=(intensity-228) as f64;likelihood_sum+=(foreground*foreground-background*background)/50.0;}
        let likelihood=likelihood_sum/samples as f64;weights[i]=(1.0/n as f64)*likelihood.exp();
    }
    let mut weight_sum=0.0;for i in 0..n{weight_sum+=weights[i];}if !weight_sum.is_finite()||weight_sum<=0.0{return -1;}
    for i in 0..n{weights[i]/=weight_sum;}
    let mut estimate_x=0.0;let mut estimate_y=0.0;for i in 0..n{estimate_x+=moved_x[i]*weights[i];estimate_y+=moved_y[i]*weights[i];}
    cdf[0]=weights[0];for i in 1..n{cdf[i]=weights[i]+cdf[i-1];}let offset=offset_raw as f64/SCALE;
    for i in 0..n{let u=offset+i as f64/n as f64;let mut selected=n-1;for j in 0..n{if cdf[j]>=u{selected=j;break;}}resampled_x[i]=moved_x[selected];resampled_y[i]=moved_y[selected];}
    let mut checksum=round_away(estimate_x)+2*round_away(estimate_y);for i in 0..n{checksum+=(2*i as i64+3)*round_away(resampled_x[i])+(2*i as i64+4)*round_away(resampled_y[i]);}checksum
}
