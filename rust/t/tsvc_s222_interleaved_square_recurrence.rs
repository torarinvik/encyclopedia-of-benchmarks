fn seed_ok(x: f64) -> bool { x == -1.0 || x == -0.5 || x == 0.0 || x == 0.5 || x == 1.0 }

#[no_mangle]
pub unsafe extern "C" fn tsvc_s222_interleaved_square_recurrence(input: *const f64, length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > 257 { return -1; }
    let values=unsafe { std::slice::from_raw_parts(input,length) };
    let rn=values[0];
    if !rn.is_finite() || rn.fract()!=0.0 || rn<1.0 || rn>64.0 { return -1; }
    let n=rn as usize;
    if length!=1+4*n { return -1; }
    if values[1..1+3*n].iter().any(|x| !x.is_finite() || x.fract()!=0.0 || x.abs()>2.0)
        || values[1+3*n..].iter().any(|x| !x.is_finite() || !seed_ok(*x)) { return -1; }
    let required=2*n;
    if output.is_null() || capacity<required { return -2; }
    let mut a=[0.0f64;64]; let mut e=[0.0f64;64];
    for i in 0..n { a[i]=values[1+i]; e[i]=values[1+3*n+i]; }
    for i in 1..n {
        let product=values[1+n+i]*values[1+2*n+i];
        a[i]=a[i]+product;
        e[i]=e[i-1]*e[i-1];
        a[i]=a[i]-product;
    }
    let out=unsafe { std::slice::from_raw_parts_mut(output,required) };
    for i in 0..n { out[i]=a[i]; out[n+i]=e[i]; }
    required as i64
}
