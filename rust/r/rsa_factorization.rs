const INVALID_RESULT: i64 = -1;
const FACTOR_BASE: i64 = 65_536;
const MAX_PACKED_LENGTH: usize = 21;

fn gcd_i64(mut a: i64, mut b: i64) -> i64 {
    if a < 0 { a = -a; }
    if b < 0 { b = -b; }
    while b != 0 { let remainder=a%b; a=b; b=remainder; }
    a
}

fn power_mod_i64(base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result=1i64;
    let mut power=base%modulus;
    while exponent>0 {
        if exponent&1 != 0 { result=(result*power)%modulus; }
        power=(power*power)%modulus;
        exponent/=2;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn rsa_factorization(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length<4 || length>MAX_PACKED_LENGTH { return INVALID_RESULT; }
    let packed=std::slice::from_raw_parts(packed,length);
    let (d,e,modulus,attempts)=(packed[0],packed[1],packed[2],packed[3]);
    if !(1..=1_000_000).contains(&d)||!(1..=1_000_000).contains(&e)||!(3..=65_535).contains(&modulus)||modulus%2==0||
        !(1..=16).contains(&attempts)||length!=(4+attempts) as usize { return INVALID_RESULT; }
    let k=d*e-1;
    if k<=0||k&1!=0 { return INVALID_RESULT; }
    if packed[4..].iter().any(|&base|base<2||base>modulus-1){return INVALID_RESULT;}
    for &base in &packed[4..] {
        let mut t=k;
        while t&1==0 {
            t/=2;
            let x=power_mod_i64(base,t,modulus);
            let factor=gcd_i64(x-1,modulus);
            if x>1&&factor>1 { let other=modulus/factor;let (p,q)=if factor<=other{(factor,other)}else{(other,factor)};return p*FACTOR_BASE+q; }
        }
    }
    INVALID_RESULT
}
