const MODULUS: i64 = 998_244_353;
#[no_mangle]
pub unsafe extern "C" fn polynomial_discrete_antiderivative(input: *const i64, length: usize,
                                                             output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(2..=33).contains(&length) { return -1; }
    let f=std::slice::from_raw_parts(input,length);
    if !(1..=32).contains(&f[0]) { return -1; }
    let n=f[0] as usize;
    if length!=n+1 || f[1..].iter().any(|&v| !(0..MODULUS).contains(&v)) { return -1; }
    if output.is_null() || capacity<8*(n+1) { return -2; }
    let mut choose=[[0i64;33];33]; let mut inverse=[0i64;33]; let mut g=[0i64;33];
    choose[0][0]=1;
    for k in 1..=n {
        choose[k][0]=1; choose[k][k]=1;
        for j in 1..k { choose[k][j]=(choose[k-1][j-1]+choose[k-1][j])%MODULUS; }
    }
    inverse[1]=1;
    for k in 2..=n { inverse[k]=MODULUS-(MODULUS/k as i64)*inverse[MODULUS as usize%k]%MODULUS; }
    for j in (0..n).rev() {
        let mut sum=0;
        for k in j+2..=n { sum=(sum+choose[k][j]*g[k])%MODULUS; }
        g[j+1]=((f[1+j]-sum+MODULUS)%MODULUS)*inverse[j+1]%MODULUS;
    }
    for (i,&value) in g[..=n].iter().enumerate() {
        std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(),output.add(8*i),8);
    }
    (8*(n+1)) as i64
}
