module laguerre_complex_polynomial_root

import math

struct Complex { re f64; im f64 }
fn c_add(a Complex,b Complex) Complex{return Complex{a.re+b.re,a.im+b.im}}
fn c_sub(a Complex,b Complex) Complex{return Complex{a.re-b.re,a.im-b.im}}
fn c_mul(a Complex,b Complex) Complex{return Complex{a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re}}
fn c_div(a Complex,b Complex) Complex{d:=b.re*b.re+b.im*b.im;return Complex{(a.re*b.re+a.im*b.im)/d,(a.im*b.re-a.re*b.im)/d}}
fn c_abs(a Complex) f64{return math.sqrt(a.re*a.re+a.im*a.im)}
fn finite(x f64) bool{return x==x&&x<=1.0e308&&x>= -1.0e308}
fn finite_c(a Complex) bool{return finite(a.re)&&finite(a.im)}
fn c_sqrt(a Complex) Complex{
    m:=c_abs(a);re:=math.sqrt(math.max(0.0,(m+a.re)*0.5));mut im:=math.sqrt(math.max(0.0,(m-a.re)*0.5));if a.im<0{im = -im};return Complex{re,im}
}
fn integer_field(x f64,lo i64,hi i64) ?i64{
    if !finite(x)||x<f64(lo)||x>f64(hi)||math.trunc(x)!=x{return none};return i64(x)
}
fn evaluate(a [7]f64,n int,z Complex)(Complex,Complex,Complex,f64){
    mut p:=Complex{a[n],0};mut dp:=Complex{0,0};mut ddp:=Complex{0,0}
    for k:=n-1;k>=0;k--{ddp=c_add(c_mul(ddp,z),Complex{2*dp.re,2*dp.im});dp=c_add(c_mul(dp,z),p);p=c_add(c_mul(p,z),Complex{a[k],0})}
    radius:=c_abs(z);mut scale:=math.abs(a[n]);for k:=n-1;k>=0;k--{scale=scale*radius+math.abs(a[k])}
    return p,dp,ddp,scale
}
fn solve(a [7]f64,n int,start Complex,tolerance f64,iterations int)?Complex{
    mut z:=start
    for step:=0;step<=iterations;step++{
        if !finite_c(z){return none}
        p,dp,ddp,scale:=evaluate(a,n,z)
        if !finite_c(p)||!finite_c(dp)||!finite_c(ddp)||!finite(scale){return none}
        if c_abs(p)<=tolerance*math.max(1.0,scale){return z}
        if step==iterations||(p.re==0&&p.im==0){return none}
        g:=c_div(dp,p);h:=c_sub(c_mul(g,g),c_div(ddp,p));rad:=c_mul(Complex{f64(n-1),0},c_sub(c_mul(Complex{f64(n),0},h),c_mul(g,g)))
        if !finite_c(g)||!finite_c(h)||!finite_c(rad){return none}
        root:=c_sqrt(rad);plus:=c_add(g,root);minus:=c_sub(g,root);den:=if c_abs(plus)>=c_abs(minus){plus}else{minus}
        dm:=c_abs(den);if dm==0||!finite(dm){return none}
        correction:=c_div(Complex{f64(n),0},den);if !finite_c(correction){return none}
        z=c_sub(z,correction)
    }
    return none
}

@[export: 'laguerre_complex_polynomial_root']
pub fn laguerre_complex_polynomial_root(input &f64,input_length usize,output &f64,output_capacity usize)i64{
    if unsafe { input == nil } || input_length<1 || input_length>13{return -1}
    degree:=integer_field(unsafe { input[0] },2,6) or { return -1 };n:=int(degree)
    if input_length!=usize(n+6){return -1}
    mut a:=[7]f64{}
    for i in 0..=n{value:=integer_field(unsafe { input[1+i] },-16,16) or { return -1 };a[i]=f64(value)}
    if a[n]==0{return -1}
    re:=integer_field(unsafe { input[n+2] },-4000,4000) or { return -1 };im:=integer_field(unsafe { input[n+3] },-4000,4000) or { return -1 }
    tolerance:=integer_field(unsafe { input[n+4] },1,1000) or { return -1 };iterations:=integer_field(unsafe { input[n+5] },8,128) or { return -1 }
    if unsafe { output == nil } || output_capacity<2{return -2}
    root:=solve(a,n,Complex{f64(re)/1000,f64(im)/1000},f64(tolerance)/1_000_000,int(iterations)) or { return -3 }
    unsafe { output[0]=root.re;output[1]=root.im }
    return 2
}
