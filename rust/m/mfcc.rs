use std::slice;

const MAX_INPUT: usize = 2054;
const MAX_AUDIO: usize = 2048;
const MAX_FFT: usize = 1024;
const MAX_FRAMES: usize = 257;
const MAX_MELS: usize = 16;
const MAX_DCTS: usize = 40;
const PI: f64 = std::f64::consts::PI;

fn fft(re: &mut [f64], im: &mut [f64]) {
    let n = re.len();
    let mut j = 0usize;
    for i in 1..n {
        let mut bit = n >> 1;
        while j & bit != 0 { j ^= bit; bit >>= 1; }
        j ^= bit;
        if i < j { re.swap(i,j); im.swap(i,j); }
    }
    let mut len = 2;
    while len <= n {
        let angle = -2.0 * PI / len as f64;
        let (sr,si) = (angle.cos(), angle.sin());
        let half = len >> 1;
        for start in (0..n).step_by(len) {
            let (mut wr,mut wi) = (1.0,0.0);
            for k in 0..half {
                let even=start+k; let odd=even+half;
                let tr=wr*re[odd]-wi*im[odd]; let ti=wr*im[odd]+wi*re[odd];
                re[odd]=re[even]-tr; im[odd]=im[even]-ti;
                re[even]+=tr; im[even]+=ti;
                let next=wr*sr-wi*si; wi=wr*si+wi*sr; wr=next;
            }
        }
        len <<= 1;
    }
}

unsafe fn run(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT { return -1; }
    let v=slice::from_raw_parts(input,length);
    let (n0,sr0,hop0,fft0,mel0,dct0)=(v[0],v[1],v[2],v[3],v[4],v[5]);
    if !(33..=MAX_AUDIO as i64).contains(&n0) || length != n0 as usize+6 { return -1; }
    if !(8000..=48000).contains(&sr0) || !(1..=50).contains(&hop0) { return -1; }
    if ![64,128,256,512,1024].contains(&fft0) || !(2..=MAX_MELS as i64).contains(&mel0) || !(1..=MAX_DCTS as i64).contains(&dct0) { return -1; }
    let (n,sr,hop_ms,fft_n,mels,dcts)=(n0 as usize,sr0 as usize,hop0 as usize,fft0 as usize,mel0 as usize,dct0 as usize);
    if n < fft_n/2+1 { return -1; }
    let hop_numerator=sr*hop_ms;
    let hop_quotient=hop_numerator/1000;
    let hop_remainder=hop_numerator%1000;
    let hop=hop_quotient+if hop_remainder>500||(hop_remainder==500&&hop_quotient%2==1){1}else{0};
    if hop==0 { return -1; }
    let mut audio=[0.0f64;MAX_AUDIO];let mut peak=0.0f64;
    for i in 0..n {let sample=f64::from_bits(v[6+i] as u64);if !sample.is_finite()||sample.abs()>1_000_000.0{return -1;}audio[i]=sample;peak=peak.max(sample.abs());}
    if peak==0.0{return -1;} for x in &mut audio[..n]{*x/=peak;}
    let pad=fft_n/2;let frames=n/hop+1;let nbins=fft_n/2+1;if frames>MAX_FRAMES{return -1;}
    let mut padded=[0.0f64;MAX_AUDIO+MAX_FFT];
    for i in 0..pad{padded[i]=audio[pad-i];}for i in 0..n{padded[pad+i]=audio[i];}for i in 0..pad{padded[pad+n+i]=audio[n-2-i];}
    let mut freqs=[0.0f64;MAX_MELS+2];let mut bins=[0usize;MAX_MELS+2];
    let mel_hi=2595.0*(1.0+(sr/2) as f64/700.0).log10();
    for i in 0..mels+2{let mel=mel_hi*i as f64/(mels+1) as f64;freqs[i]=700.0*(10.0f64.powf(mel/2595.0)-1.0);let b=((fft_n+1) as f64/sr as f64*freqs[i]).floor();if b<0.0||b>=nbins as f64{return -1;}bins[i]=b as usize;}
    for i in 0..mels+1{if bins[i]>=bins[i+1]{return -1;}}
    let mut norms=[0.0f64;MAX_MELS];for i in 0..mels{norms[i]=2.0/(freqs[i+2]-freqs[i]);if !norms[i].is_finite(){return -1;}}
    let mut logged=[[0.0f64;MAX_FRAMES];MAX_MELS];let mut win=[0.0f64;MAX_FFT];for i in 0..fft_n{win[i]=0.5-0.5*(2.0*PI*i as f64/fft_n as f64).cos();}
    for frame in 0..frames{
        let mut re=[0.0f64;MAX_FFT];let mut im=[0.0f64;MAX_FFT];for i in 0..fft_n{re[i]=padded[frame*hop+i]*win[i];}
        fft(&mut re[..fft_n],&mut im[..fft_n]);let mut power=[0.0f32;MAX_FFT/2+1];
        for k in 0..nbins{let r=re[k] as f32;let q=im[k] as f32;let mag=r.hypot(q);power[k]=mag*mag;}
        for f in 0..mels{let (start,mid,end)=(bins[f],bins[f+1],bins[f+2]);let (rise,fall)=(mid-start,end-mid);let mut energy=0.0f64;
            for k in start..mid{let w=if rise==1{0.0}else{(k-start) as f64/(rise-1) as f64};energy+=power[k] as f64*w;}
            for k in mid..end{let w=if fall==1{1.0}else{1.0-(k-mid) as f64/(fall-1) as f64};energy+=power[k] as f64*w;}
            energy*=norms[f];if !energy.is_finite()||energy<=0.0{return -1;}logged[f][frame]=10.0*energy.log10();
        }
    }
    let mut result=[[0.0f64;MAX_FRAMES];MAX_DCTS];
    for d in 0..dcts{let scale=if d==0{1.0/(mels as f64).sqrt()}else{(2.0/mels as f64).sqrt()};for frame in 0..frames{let mut sum=0.0;for j in 0..mels{let basis=if d==0{scale}else{scale*((d*(2*j+1)) as f64*PI/(2.0*mels as f64)).cos()};sum+=basis*logged[j][frame];}if !sum.is_finite(){return -1;}result[d][frame]=sum;}}
    let bytes=dcts*frames*8;if output.is_null()||capacity<bytes{return -2;}
    let mut pos=0;for d in 0..dcts{for frame in 0..frames{let bits=result[d][frame].to_bits().to_le_bytes();std::ptr::copy_nonoverlapping(bits.as_ptr(),output.add(pos),8);pos+=8;}}
    bytes as i64
}

#[no_mangle]
pub unsafe extern "C" fn mfcc(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{run(input,length,output,capacity)}
