// New bounded relaxed-convolution schedule; see benchmarks/r/relaxed_convolution/README.md and LICENSE.txt.
use std::slice;
const MODULUS:i64=998_244_353;
#[no_mangle]
pub unsafe extern "C" fn relaxed_convolution(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<3||length>33{return -1;}let values=slice::from_raw_parts(input,length);let n0=values[0];if n0<1||n0>16||length!=1+2*n0 as usize{return -1;}let n=n0 as usize;
    let(mut a,mut b,mut c)=([0_i64;16],[0_i64;16],[0_i64;16]);for i in 0..n{a[i]=values[1+i];b[i]=values[1+n+i];if a[i]<0||a[i]>=MODULUS||b[i]<0||b[i]>=MODULUS{return -1;}}
    if output.is_null()||capacity<4*n{return -2;}let out=slice::from_raw_parts_mut(output,capacity);
    for index in 0..n{c[index]=(c[index]+a[index]*b[0])%MODULUS;if index>0{c[index]=(c[index]+b[index]*a[0])%MODULUS;}let q=index+1;let mut d=1;
        while d<=q{if q%(2*d)==d{let end=(q+d).min(n);if q==d{for i in q..end{let target=d+i-q;for r in 0..d{let y=target-r;if y<d{c[i]=(c[i]+a[r]*b[y])%MODULUS;}}}}else{for i in q..end{let target=d+i-q;for r in 0..d{let y=target-r;if y<2*d{c[i]=(c[i]+a[q-d+r]*b[y]+b[q-d+r]*a[y])%MODULUS;}}}}}d*=2;}
    }
    for i in 0..n{let x=c[i] as u32;for j in 0..4{out[4*i+j]=(x>>(8*j)) as u8;}}(4*n) as i64
}
