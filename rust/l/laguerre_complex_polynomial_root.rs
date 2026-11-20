#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(a: C, b: C) -> C { C { re: a.re+b.re, im: a.im+b.im } }
    fn sub(a: C, b: C) -> C { C { re: a.re-b.re, im: a.im-b.im } }
    fn mul(a: C, b: C) -> C { C { re: a.re*b.re-a.im*b.im, im: a.re*b.im+a.im*b.re } }
    fn div(a: C, b: C) -> C {
        let d=b.re*b.re+b.im*b.im;
        C { re:(a.re*b.re+a.im*b.im)/d, im:(a.im*b.re-a.re*b.im)/d }
    }
    fn abs(a: C) -> f64 { a.re.hypot(a.im) }
    fn finite(a: C) -> bool { a.re.is_finite() && a.im.is_finite() }
    fn sqrt(a: C) -> C {
        let m=C::abs(a);
        let re=((m+a.re)*0.5).max(0.0).sqrt();
        let mut im=((m-a.re)*0.5).max(0.0).sqrt();
        if a.im<0.0 { im = -im; }
        C { re, im }
    }
}
fn integer_field(value: f64, low: i64, high: i64) -> Option<i64> {
    if !value.is_finite() || value < low as f64 || value > high as f64 || value.fract()!=0.0 { None }
    else { Some(value as i64) }
}
fn evaluate(a: &[f64], n: usize, z: C) -> (C,C,C,f64) {
    let mut p=C{re:a[n],im:0.0};
    let mut dp=C{re:0.0,im:0.0};
    let mut ddp=C{re:0.0,im:0.0};
    for k in (0..n).rev() {
        ddp=C::add(C::mul(ddp,z),C{re:2.0*dp.re,im:2.0*dp.im});
        dp=C::add(C::mul(dp,z),p);
        p=C::add(C::mul(p,z),C{re:a[k],im:0.0});
    }
    let radius=C::abs(z);
    let mut scale=a[n].abs();
    for k in (0..n).rev() { scale=scale*radius+a[k].abs(); }
    (p,dp,ddp,scale)
}
fn solve(a: &[f64], n: usize, mut z: C, tolerance: f64, iterations: usize) -> Option<C> {
    for step in 0..=iterations {
        if !C::finite(z) { return None; }
        let (p,dp,ddp,scale)=evaluate(a,n,z);
        if !C::finite(p)||!C::finite(dp)||!C::finite(ddp)||!scale.is_finite() { return None; }
        if C::abs(p)<=tolerance*scale.max(1.0) { return Some(z); }
        if step==iterations || (p.re==0.0&&p.im==0.0) { return None; }
        let g=C::div(dp,p);
        let h=C::sub(C::mul(g,g),C::div(ddp,p));
        let rad=C::mul(C{re:(n-1) as f64,im:0.0},
            C::sub(C::mul(C{re:n as f64,im:0.0},h),C::mul(g,g)));
        if !C::finite(g)||!C::finite(h)||!C::finite(rad) { return None; }
        let root=C::sqrt(rad);let plus=C::add(g,root);let minus=C::sub(g,root);
        let denominator=if C::abs(plus)>=C::abs(minus){plus}else{minus};
        let denominator_abs=C::abs(denominator);
        if denominator_abs==0.0||!denominator_abs.is_finite(){return None;}
        let correction=C::div(C{re:n as f64,im:0.0},denominator);
        if !C::finite(correction){return None;}
        z=C::sub(z,correction);
    }
    None
}

#[no_mangle]
pub unsafe extern "C" fn laguerre_complex_polynomial_root(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null()||input_length<1||input_length>13{return -1;}
    let values=std::slice::from_raw_parts(input,input_length);
    let degree=match integer_field(values[0],2,6){Some(v)=>v as usize,None=>return -1};
    if input_length!=degree+6{return -1;}
    let mut a=[0.0_f64;7];
    for i in 0..=degree { match integer_field(values[1+i],-16,16){Some(v)=>a[i]=v as f64,None=>return -1} }
    if a[degree]==0.0{return -1;}
    let re=match integer_field(values[degree+2],-4000,4000){Some(v)=>v,None=>return -1};
    let im=match integer_field(values[degree+3],-4000,4000){Some(v)=>v,None=>return -1};
    let tol=match integer_field(values[degree+4],1,1000){Some(v)=>v,None=>return -1};
    let iterations=match integer_field(values[degree+5],8,128){Some(v)=>v as usize,None=>return -1};
    if output.is_null()||output_capacity<2{return -2;}
    let initial=C{re:re as f64/1000.0,im:im as f64/1000.0};
    match solve(&a[..=degree],degree,initial,tol as f64/1_000_000.0,iterations){
        Some(root) if C::finite(root)=>{*output=root.re;*output.add(1)=root.im;2}
        _=>-3,
    }
}
