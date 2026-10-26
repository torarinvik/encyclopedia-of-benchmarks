const MOD: i64 = 998_244_353;
fn rank(mask: usize) -> usize { mask.count_ones() as usize }
fn put(out: &mut [u8], off: usize, value: i64) { out[off..off+8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn fast_subset_convolution(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 33 { return -1; }
    let v=unsafe{core::slice::from_raw_parts(input,length)}; let n0=v[0];
    if !(0..=4).contains(&n0) { return -1; }
    let n=n0 as usize; let size=1usize<<n; if length!=1+2*size{return -1;}
    if v[1..].iter().any(|&x|x<0||x>=MOD){return -1;}
    let mut f=[[0i64;16];5]; let mut g=[[0i64;16];5]; let mut h=[[0i64;16];5];
    for s in 0..size {let r=rank(s);f[r][s]=v[1+s];g[r][s]=v[1+size+s];}
    for bit in 0..n {for s in 0..size {if s&(1<<bit)!=0 {let other=s^(1<<bit);for r in 0..=n {f[r][s]=(f[r][s]+f[r][other])%MOD;g[r][s]=(g[r][s]+g[r][other])%MOD;}}}}
    for s in 0..size {for r in 0..=n {let mut sum=0i64;for i in 0..=r {sum=(sum+f[i][s]*g[r-i][s])%MOD;}h[r][s]=sum;}}
    for bit in 0..n {for s in 0..size {if s&(1<<bit)!=0 {let other=s^(1<<bit);for r in 0..=n {h[r][s]=(h[r][s]-h[r][other]+MOD)%MOD;}}}}
    let required=size*8;if capacity<required||output.is_null(){return -2;}
    let out=unsafe{core::slice::from_raw_parts_mut(output,required)};for s in 0..size{put(out,8*s,h[rank(s)][s]);}required as i64
}
