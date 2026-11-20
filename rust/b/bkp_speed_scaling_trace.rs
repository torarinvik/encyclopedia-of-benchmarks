const MAX_JOBS: usize = 4;
const MAX_SAMPLES: usize = 8;
const E_NUM: i64 = 271_828;
const E_DEN: i64 = 100_000;
const EM1_NUM: i64 = 171_828;

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let r = a % b; a = b; b = r; }
    if a < 0 { -a } else { a }
}
fn consider(r: &[i64;MAX_JOBS], d: &[i64;MAX_JOBS], w: &[i64;MAX_JOBS],
    n: usize, t: i64, x_num: i64, x_den: i64, best: &mut (i64,i64)) {
    let delta=x_num-t*x_den;
    if delta<=0 { return; }
    let left=E_NUM*t*x_den-EM1_NUM*x_num;
    let total: i64=(0..n).filter(|&j| r[j]<=t && left<=E_DEN*x_den*r[j] && d[j]*x_den<=x_num).map(|j|w[j]).sum();
    let num=total*x_den;
    if num*best.1>best.0*delta { *best=(num,delta); }
}
unsafe fn store(out: *mut u8, at: usize, value: i64) {
    let bits=value as u64;
    for b in 0..8 { *out.add(at+b)=(bits>>(8*b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn bkp_speed_scaling_trace(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length<2 || length>31 { return -1; }
    let n64=*input; let s64=*input.add(1);
    if !(1..=4).contains(&n64) || !(1..=8).contains(&s64) { return -1; }
    let n=n64 as usize; let samples=s64 as usize;
    if length!=2+3*n+2*samples { return -1; }
    let mut r=[0i64;MAX_JOBS]; let mut d=[0i64;MAX_JOBS]; let mut w=[0i64;MAX_JOBS];
    for j in 0..n {
        r[j]=*input.add(2+3*j); d[j]=*input.add(3+3*j); w[j]=*input.add(4+3*j);
        if r[j]<0 || r[j]>=d[j] || d[j]>8 || w[j]<1 || w[j]>8 { return -1; }
    }
    let mut values=[0i64;17]; values[0]=s64;
    for s in 0..samples {
        let t=*input.add(2+3*n+2*s); let mask=*input.add(3+3*n+2*s);
        if !(0..=8).contains(&t) || mask<0 || mask >= (1i64<<n) { return -1; }
        for j in 0..n { if mask&(1<<j)!=0 && r[j]>t { return -1; } }
        let mut best=(0i64,1i64);
        if mask!=0 { for j in 0..n { if r[j]<=t {
            if d[j]>t { consider(&r,&d,&w,n,t,d[j],1,&mut best); }
            if r[j]<t { consider(&r,&d,&w,n,t,E_NUM*t-E_DEN*r[j],EM1_NUM,&mut best); }
        }}}
        let g=gcd(best.0,best.1); values[1+2*s]=best.0/g; values[2+2*s]=best.1/g;
    }
    let bytes=8*(1+2*samples);
    if output.is_null() || capacity<bytes { return -2; }
    let mut staged=[0u8;136];
    for i in 0..1+2*samples { store(staged.as_mut_ptr(),8*i,values[i]); }
    for i in 0..bytes { *output.add(i)=staged[i]; }
    bytes as i64
}
