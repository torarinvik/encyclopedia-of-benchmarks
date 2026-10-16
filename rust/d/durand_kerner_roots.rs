use std::ffi::c_void;

#[derive(Clone, Copy)]
struct C { r: f64, i: f64 }
impl C {
    fn sub(a: C, b: C) -> C { C { r: a.r-b.r, i: a.i-b.i } }
    fn mul(a: C, b: C) -> C { C { r: a.r*b.r-a.i*b.i, i: a.r*b.i+a.i*b.r } }
    fn div(a: C, b: C) -> C {
        let den=b.r*b.r+b.i*b.i;
        C { r:(a.r*b.r+a.i*b.i)/den, i:(a.i*b.r-a.r*b.i)/den }
    }
    fn abs(a: C) -> f64 { (a.r*a.r+a.i*a.i).sqrt() }
}

#[no_mangle]
pub unsafe extern "C" fn durand_kerner_roots(v: *const i64, n: usize) -> f64 {
    if v.is_null() || n != 3 { return -1.0e300; }
    let d=*v;
    let ri=*v.add(1);
    let part=*v.add(2);
    if d == 0 || d < -4 || d > 4 || ri < 0 || ri > 2 || part < 0 || part > 1 { return -1.0e300; }
    let s=if d>0 {1.0} else {-1.0};
    let q=3.0f64.sqrt()/2.0;
    let mut z=[C{r:s,i:0.0}, C{r:-0.5*s,i:q*s}, C{r:-0.5*s,i:-q*s}];
    for _ in 0..100 {
        let mut next=z;
        let mut change=0.0f64;
        for i in 0..3 {
            let mut den=C{r:1.0,i:0.0};
            for j in 0..3 { if i!=j { den=C::mul(den,C::sub(z[i],z[j])); } }
            let z2=C::mul(z[i],z[i]);
            let z3=C::mul(z2,z[i]);
            next[i]=C::sub(z[i],C::div(C::sub(z3,C{r:d as f64,i:0.0}),den));
            change=change.max(C::abs(C::sub(next[i],z[i])));
        }
        z=next;
        if change < 1.0e-14 { break; }
    }
    if part==0 { z[ri as usize].r } else { z[ri as usize].i }
}
