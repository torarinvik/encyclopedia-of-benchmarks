// Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt.
const CHANNELS: usize = 20;
const MAX_N: usize = 64;
const AMINO_CODES: [i64; CHANNELS] = [65,82,78,68,67,81,69,71,72,73,76,75,77,70,80,83,84,87,89,86];
const POLARITY: [f64; CHANNELS] = [8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9];
const VOLUME: [f64; CHANNELS] = [31.0,124.0,56.0,54.0,55.0,85.0,83.0,3.0,96.0,111.0,111.0,119.0,105.0,132.0,32.5,32.0,61.0,170.0,136.0,84.0];
fn channel(code: i64) -> Option<usize> { AMINO_CODES.iter().position(|&v| v == code) }
fn fft(re: &mut [f64; MAX_N], im: &mut [f64; MAX_N], n: usize, inverse: bool) {
    let mut j=0usize;
    for i in 1..n { let mut bit=n>>1; while j&bit!=0 {j^=bit;bit>>=1;} j^=bit; if i<j {re.swap(i,j);im.swap(i,j);} }
    let mut span=2;
    while span<=n {let angle=(if inverse {1.0} else {-1.0})*6.2831853071795864769/span as f64;let (cr,ci)=(angle.cos(),angle.sin());let mut start=0;while start<n {let(mut wr,mut wi)=(1.0,0.0);for k in 0..span/2 {let u=start+k;let v=u+span/2;let(pr,pi)=(wr*re[v]-wi*im[v],wr*im[v]+wi*re[v]);let(ur,ui)=(re[u],im[u]);re[u]=ur+pr;im[u]=ui+pi;re[v]=ur-pr;im[v]=ui-pi;let nw=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nw;}start+=span;}span*=2;}
    if !inverse {for q in 0..n {re[q]/=n as f64;im[q]/=n as f64;}}
}

#[no_mangle]
pub unsafe extern "C" fn mafft_falign_fft_lag_correlation(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64 {
    if input.is_null()||!(4..=66).contains(&length){return -1;}
    for q in 0..length {let v=*input.add(q);if !v.is_finite()||v.fract()!=0.0{return -1;}}
    let n1=*input as usize;let n2=*input.add(1) as usize;if !(1..=32).contains(&n1)||!(1..=32).contains(&n2)||length!=2+n1+n2{return -1;}
    for q in 2..length {let code=*input.add(q);if !(65.0..=90.0).contains(&code)||channel(code as i64).is_none(){return -1;}}
    let mut n=1;while n<=n1.max(n2){n*=2;}if output.is_null()||capacity<n{return -2;}
    let mut r1=[0.0;MAX_N];let mut i1=[0.0;MAX_N];let mut r2=[0.0;MAX_N];let mut i2=[0.0;MAX_N];let mut re=[0.0;MAX_N];let mut im=[0.0;MAX_N];
    let mut mp=0.0;let mut mv=0.0;for ch in 0..CHANNELS{mp+=POLARITY[ch];mv+=VOLUME[ch];}mp/=CHANNELS as f64;mv/=CHANNELS as f64;
    let mut vp=0.0;let mut vv=0.0;for ch in 0..CHANNELS{let dp=POLARITY[ch]-mp;let dv=VOLUME[ch]-mv;vp+=dp*dp;vv+=dv*dv;}let sp=(vp/CHANNELS as f64).sqrt();let sv=(vv/CHANNELS as f64).sqrt();
    for p in 0..n1{let ch=channel(*input.add(2+p) as i64).unwrap();r1[p]=(POLARITY[ch]-mp)/sp;i1[p]=(VOLUME[ch]-mv)/sv;}
    for p in 0..n2{let ch=channel(*input.add(2+n1+p) as i64).unwrap();r2[p]=(POLARITY[ch]-mp)/sp;i2[p]=(VOLUME[ch]-mv)/sv;}
    fft(&mut r1,&mut i1,n,false);fft(&mut r2,&mut i2,n,false);for k in 0..n{re[k]=r1[k]*r2[k]+i1[k]*i2[k];im[k]=-r1[k]*i2[k]+i1[k]*r2[k];}
    fft(&mut re,&mut im,n,true);for q in 0..n {*output.add(q)=re[(n/2+n-q)%n];}n as i64
}
