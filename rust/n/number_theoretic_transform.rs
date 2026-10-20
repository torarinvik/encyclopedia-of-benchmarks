// New bounded port based on AtCoder Library convolution semantics (CC0); see benchmarks/n/number_theoretic_transform/LICENSE.txt.
use std::slice;
const MODULUS: i64 = 998_244_353;
fn mod_pow(mut a: i64, mut exponent: i64) -> i64 { let mut result=1; while exponent>0 { if exponent&1 != 0 { result=result*a%MODULUS; } a=a*a%MODULUS; exponent >>= 1; } result }
#[no_mangle]
pub unsafe extern "C" fn number_theoretic_transform(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length<2 || length>65 { return -1; }
    let values=slice::from_raw_parts(input,length); let n0=values[0];
    if n0<1 || n0>64 || n0&(n0-1)!=0 || length!=n0 as usize+1 { return -1; }
    let n=n0 as usize; let mut a=[0_i64;64];
    for i in 0..n { if values[i+1]<0 || values[i+1]>=MODULUS { return -1; } a[i]=values[i+1]; }
    if output.is_null() || capacity<4*n { return -2; }
    let out=slice::from_raw_parts_mut(output,capacity);
    let mut j=0; for i in 1..n { let mut bit=n>>1; while j&bit!=0 { j^=bit;bit>>=1; } j^=bit; if i<j { a.swap(i,j); } }
    let mut len=2; while len<=n { let step=mod_pow(3,(MODULUS-1)/len as i64); let mut base=0; while base<n { let mut w=1_i64; for k in 0..len/2 { let u=a[base+k];let v=a[base+k+len/2]*w%MODULUS;a[base+k]=(u+v)%MODULUS;a[base+k+len/2]=(u-v+MODULUS)%MODULUS;w=w*step%MODULUS; } base+=len; } len*=2; }
    for i in 0..n { let x=a[i] as u32; for b in 0..4 { out[4*i+b]=(x>>(8*b)) as u8; } }
    (4*n) as i64
}
