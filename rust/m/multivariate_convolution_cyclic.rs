const MAX_P: usize = 32;
const MAX_K: usize = 3;
const MAX_INPUT: usize = 70;
const MAX_OUTPUT: usize = 256;
unsafe fn store_le(output:*mut u8,offset:usize,value:i64){let bits=value as u64;for b in 0..8{*output.add(offset+b)=((bits>>(8*b))&255)as u8;}}
fn is_prime(p:i64)->bool{if p<2{return false;}let mut d=2;while d*d<=p as usize{if p%d as i64==0{return false;}d+=1;}true}
#[no_mangle]
pub unsafe extern "C" fn multivariate_convolution_cyclic(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<2||length>MAX_INPUT{return -1;}let w=std::slice::from_raw_parts(input,length);let p0=w[0];let k0=w[1];
    if p0<2||p0>97||!is_prime(p0)||k0<0||k0 as usize>MAX_K{return -1;}let p=p0 as usize;let k=k0 as usize;if length<2+k{return -1;}
    let mut dims=[0usize;MAX_K];let mut product=1usize;for axis in 0..k{let d0=w[2+axis];if d0<2||d0 as usize>MAX_P||(p-1)%d0 as usize!=0||product>MAX_P/d0 as usize{return -1;}dims[axis]=d0 as usize;product*=dims[axis];}
    let start=2+k;if length!=start+2*product{return -1;}if w[start..].iter().any(|&x|x<0||x>=p0){return -1;}let bytes=8*product;if bytes>MAX_OUTPUT{return -1;}if output.is_null()||capacity<bytes{return -2;}
    let mut a=[0i64;MAX_P];let mut b=[0i64;MAX_P];let mut result=[0i64;MAX_P];for i in 0..product{a[i]=w[start+i];b[i]=w[start+product+i];}
    for i in 0..product{for j in 0..product{let mut target=0;let mut stride=1;for axis in 0..k{let d=dims[axis];let sum=((i/stride)%d+(j/stride)%d)%d;target+=sum*stride;stride*=d;}result[target]=(result[target]+a[i]*b[j])%p0;}}
    for i in 0..product{store_le(output,8*i,result[i]);}bytes as i64
}
