fn f32_value(x: f32) -> f32 { x }

#[no_mangle]
pub unsafe extern "C" fn cbench_rsynth_natural_glottal_sample(input: *const f64,n:usize,output:*mut f64,cap:usize)->i64{
    if input.is_null()||n==0||n>3{return -1}
    let v=unsafe{std::slice::from_raw_parts(input,n)};
    if v.iter().any(|x|!x.is_finite()){return -1}
    if n!=2||v[0]<40.0||v[0]>263.0||v[0].trunc()!=v[0]||v[1]<0.0||v[1]>299.0||v[1].trunc()!=v[1]{return -1}
    let nopen=v[0] as i64;let index=v[1] as i64;let mut result=0.0_f32;
    if index<nopen{
        let b_int=1_920_000/(nopen*nopen) as i32;let b=f32_value(b_int as f32);
        let product=f32_value(b*f32_value(nopen as f32));
        let mut a=f32_value((product as f64*0.333) as f32);let mut wave=0.0_f32;
        for _ in 0..=index{a=f32_value(a-b);wave=f32_value(wave+a)}
        result=f32_value((wave as f64*0.028) as f32);
    }
    if output.is_null()||cap<1{return -2}
    unsafe{*output=result as f64;}1
}
