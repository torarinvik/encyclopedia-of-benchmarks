const MAX_N: usize = 16;
const MAX_INPUT: usize = 50;

fn power(base: i64, exponent: i64) -> i64 {
    let mut result = 1;
    for _ in 0..exponent { result *= base; }
    result
}
fn before(w: &[i64; MAX_N], a: &[i64; MAX_N], b: &[i64; MAX_N], i: i64, j: i64) -> bool {
    let (i, j) = (i as usize, j as usize);
    let lhs = power(a[i], w[j]) * power(b[j], w[i]);
    let rhs = power(a[j], w[i]) * power(b[i], w[j]);
    lhs > rhs || (lhs == rhs && i < j)
}
unsafe fn put64(out: *mut u8, pos: usize, value: i64) {
    let bits = value as u64;
    for j in 0..8 { *out.add(pos+j) = (bits >> (8*j)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn weighted_random_sampling(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let n64=*input; let m64=*input.add(1);
    if n64<1 || n64>MAX_N as i64 || m64<1 || m64>n64 || length!=2+3*n64 as usize { return -1; }
    let n=n64 as usize; let m=m64 as usize;
    let mut w=[0i64;MAX_N]; let mut a=[0i64;MAX_N]; let mut b=[0i64;MAX_N];
    for i in 0..n { w[i]=*input.add(2+3*i); a[i]=*input.add(3+3*i); b[i]=*input.add(4+3*i);
        if w[i]<1 || w[i]>3 || a[i]<1 || a[i]>=b[i] || b[i]>100 { return -1; }
    }
    let bytes=8*m; if output.is_null() || capacity<bytes { return -2; }
    let mut available=[0i64;MAX_N]; let mut chosen=[0i64;MAX_N];
    for i in 0..n { available[i]=i as i64; }
    for rank in 0..m { let mut best=0; for i in 1..n-rank { if before(&w,&a,&b,available[i],available[best]) {best=i;} }
        chosen[rank]=available[best]; for i in best..n-rank-1 {available[i]=available[i+1];}
    }
    for i in 0..m { put64(output,8*i,chosen[i]); }
    bytes as i64
}
