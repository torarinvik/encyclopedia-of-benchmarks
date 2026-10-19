const INPUT_LENGTH: usize = 48;
#[inline(never)] fn add32(a:f32,b:f32)->f32 { a+b }
#[inline(never)] fn sub32(a:f32,b:f32)->f32 { a-b }
#[inline(never)] fn mul32(a:f32,b:f32)->f32 { a*b }

#[no_mangle]
pub unsafe extern "C" fn versabench_beamformer(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    if input.is_null()||length!=INPUT_LENGTH{return -1}
    let src=std::slice::from_raw_parts(input,length);let mut v=[0f32;INPUT_LENGTH];
    for i in 0..INPUT_LENGTH{let x=src[i];if !x.is_finite()||x < -128.0||x > 128.0{return -1}v[i]=x as f32;}
    let(mut real,mut imag)=(0f32,0f32);
    for c in 0..12{let b=4*c;let rr=sub32(mul32(v[b],v[b+2]),mul32(v[b+1],v[b+3]));let ii=add32(mul32(v[b],v[b+3]),mul32(v[b+1],v[b+2]));real=add32(real,rr);imag=add32(imag,ii);}
    if output.is_null()||capacity<2{return -2}*output=real as f64;*output.add(1)=imag as f64;2
}
