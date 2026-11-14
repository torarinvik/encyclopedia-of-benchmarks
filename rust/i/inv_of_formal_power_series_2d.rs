const P: i64=998_244_353;
fn power(mut x:i64, mut e:i64)->i64 {
    let mut result=1;
    while e>0 { if e&1!=0 { result=result*x%P; } x=x*x%P; e>>=1; }
    result
}
#[no_mangle]
pub unsafe extern "C" fn inv_of_formal_power_series_2d(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
    if input.is_null() || !(3..=66).contains(&length) { return -1; }
    let f=std::slice::from_raw_parts(input,length);
    if !(1..=8).contains(&f[0]) || !(1..=8).contains(&f[1]) { return -1; }
    let (n,m)=(f[0] as usize,f[1] as usize);
    if length!=2+n*m || f[2]==0 || f[2..].iter().any(|&x| !(0..P).contains(&x)) { return -1; }
    if output.is_null() || capacity<8*n*m { return -2; }
    let mut g=[0i64;64]; let inverse=power(f[2],P-2); g[0]=inverse;
    for i in 0..n { for j in 0..m {
        if i==0 && j==0 { continue; }
        let mut sum=0;
        for a in 0..=i { for b in 0..=j {
            if a!=0 || b!=0 { sum=(sum+f[2+a*m+b]*g[(i-a)*m+j-b])%P; }
        }}
        g[i*m+j]=((P-sum)%P)*inverse%P;
    }}
    for (i,&v) in g[..n*m].iter().enumerate() {
        std::ptr::copy_nonoverlapping(v.to_le_bytes().as_ptr(),output.add(8*i),8);
    }
    (8*n*m) as i64
}
