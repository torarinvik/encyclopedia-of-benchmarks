const MODULUS: i64 = 998_244_353;
fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result*base%MODULUS; }
        base = base*base%MODULUS;
        exponent >>= 1;
    }
    result
}
#[no_mangle]
pub unsafe extern "C" fn dirichlet_inverse_and_prefix_sums(input: *const i64, length: usize,
                                                           output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(2..=16).contains(&length) { return -1; }
    let f=std::slice::from_raw_parts(input,length);
    if !(1..=64).contains(&f[0]) { return -1; }
    let n=f[0] as usize;
    let mut q=Vec::new();
    for i in (1..=n).rev() {
        let x=n/i;
        if q.last().copied() != Some(x) { q.push(x); }
    }
    if length != 1+q.len() || f[1] == 0 || f[1..].iter().any(|&v| !(0..MODULUS).contains(&v)) { return -1; }
    if output.is_null() || capacity < 8*q.len() { return -2; }
    let inverse=power(f[1],MODULUS-2);
    let mut g=vec![0i64; q.len()];
    for i in 0..q.len() {
        let x=q[i]; let mut left=2; let mut total=0;
        while left <= x {
            let k=x/left; let right=x/k;
            let hi=match q.binary_search(&right) { Ok(v)=>v, Err(_)=>return -1 };
            let lo=match q.binary_search(&(left-1)) { Ok(v)=>v, Err(_)=>return -1 };
            let gi=match q.binary_search(&k) { Ok(v)=>v, Err(_)=>return -1 };
            let interval=(f[1+hi]-f[1+lo]+MODULUS)%MODULUS;
            total=(total+interval*g[gi])%MODULUS;
            left=right+1;
        }
        g[i]=((1-total+MODULUS)%MODULUS)*inverse%MODULUS;
    }
    for (i,&value) in g.iter().enumerate() {
        std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(),output.add(8*i),8);
    }
    (8*q.len()) as i64
}
