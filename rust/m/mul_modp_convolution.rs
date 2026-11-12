const MAX_P: usize = 97;
const MAX_INPUT: usize = 196;
const MAX_OUTPUT: usize = 776;
const MOD: i64 = 998_244_353;

fn pow_mod(mut base: i64, mut exponent: usize, modulus: usize) -> usize {
    let mut result: i64 = 1;
    base %= modulus as i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % modulus as i64; }
        base = base * base % modulus as i64;
        exponent >>= 1;
    }
    result as usize
}

fn is_prime(p: usize) -> bool {
    if p < 2 { return false; }
    let mut d=2usize; while d*d<=p { if p%d==0{return false;} d+=1; }
    true
}

fn primitive_root(p: usize) -> usize {
    let order=p-1;
    for candidate in 1..p {
        let mut ok=true;
        for factor in 2..=order {
            if order%factor!=0 { continue; }
            let mut prime=true;let mut d=2usize;
            while d*d<=factor { if factor%d==0 {prime=false;break;} d+=1; }
            if prime && pow_mod(candidate as i64,order/factor,p)==1 {ok=false;break;}
        }
        if ok{return candidate;}
    }
    1
}

unsafe fn store_le(output:*mut u8,offset:usize,value:i64){let bits=value as u64;for b in 0..8{*output.add(offset+b)=((bits>>(8*b))&255) as u8;}}

#[no_mangle]
pub unsafe extern "C" fn mul_modp_convolution(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<5||length>MAX_INPUT{return -1;}
    let words=std::slice::from_raw_parts(input,length);let p0=words[0];
    if p0<2||p0>MAX_P as i64||!is_prime(p0 as usize){return -1;}
    let p=p0 as usize;if length!=1+2*p{return -1;}
    if words[1..].iter().any(|&x|x<0||x>=MOD){return -1;}
    let bytes=8*p;if bytes>MAX_OUTPUT{return -1;}if output.is_null()||capacity<bytes{return -2;}
    let mut a=[0i64;MAX_P];let mut b=[0i64;MAX_P];
    for i in 0..p{a[i]=words[1+i];b[i]=words[1+p+i];}
    let q=p-1;let root=primitive_root(p);let mut by_exp=[0usize;MAX_P];let mut residue=1usize;
    for e in 0..q{by_exp[e]=residue;residue=residue*root%p;}
    let mut left=[0i64;MAX_P];let mut right=[0i64;MAX_P];let mut cyclic=[0i64;MAX_P];
    for e in 0..q{left[e]=a[by_exp[e]];right[e]=b[by_exp[e]];}
    for i in 0..q{for j in 0..q{let slot=(i+j)%q;cyclic[slot]=(cyclic[slot]+left[i]*right[j]%MOD)%MOD;}}
    let mut sum_a=0i64;let mut sum_b=0i64;
    for i in 0..p{sum_a=(sum_a+a[i])%MOD;}
    for i in 1..p{sum_b=(sum_b+b[i])%MOD;}
    let mut result=[0i64;MAX_P];result[0]=(sum_a*b[0]%MOD+a[0]*sum_b%MOD)%MOD;
    for e in 0..q{result[by_exp[e]]=cyclic[e];}
    for i in 0..p{store_le(output,8*i,result[i]);}
    bytes as i64
}
