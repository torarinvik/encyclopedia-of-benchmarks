package laguerre_complex_polynomial_root

import "core:c"
import "core:math"

Cplx :: struct { re, im: f64 }
add :: proc "contextless" (a,b:Cplx)->Cplx{return {a.re+b.re,a.im+b.im}}
sub :: proc "contextless" (a,b:Cplx)->Cplx{return {a.re-b.re,a.im-b.im}}
mul :: proc "contextless" (a,b:Cplx)->Cplx{return {a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re}}
divc :: proc "contextless" (a,b:Cplx)->Cplx{d:=b.re*b.re+b.im*b.im;return {(a.re*b.re+a.im*b.im)/d,(a.im*b.re-a.re*b.im)/d}}
mag :: proc "contextless" (a:Cplx)->f64{return math.sqrt(a.re*a.re+a.im*a.im)}
finite :: proc "contextless" (x:f64)->bool{return x==x&&x<=1.0e308&&x>= -1.0e308}
finite_c :: proc "contextless" (a:Cplx)->bool{return finite(a.re)&&finite(a.im)}
sqrt_c :: proc "contextless" (a:Cplx)->Cplx{
    m:=mag(a);re:=math.sqrt(math.max(0.0,(m+a.re)*0.5));im:=math.sqrt(math.max(0.0,(m-a.re)*0.5));if a.im<0 do im = -im
    return {re,im}
}
integer_field :: proc "contextless" (x:f64,lo,hi:i64)->(i64,bool){
    if !finite(x)||x<f64(lo)||x>f64(hi)||math.trunc(x)!=x do return 0,false
    return i64(x),true
}
evaluate :: proc "contextless" (a:[7]f64,n:int,z:Cplx)->(Cplx,Cplx,Cplx,f64){
    p:=Cplx{a[n],0};dp:=Cplx{0,0};ddp:=Cplx{0,0}
    for k:=n-1;k>=0;k-=1{ddp=add(mul(ddp,z),Cplx{2*dp.re,2*dp.im});dp=add(mul(dp,z),p);p=add(mul(p,z),Cplx{a[k],0})}
    radius:=mag(z);scale:=math.abs(a[n]);for k:=n-1;k>=0;k-=1{scale=scale*radius+math.abs(a[k])}
    return p,dp,ddp,scale
}
solve :: proc "contextless" (a:[7]f64,n:int,z0:Cplx,tolerance:f64,iterations:int)->(Cplx,bool){
    z:=z0
    for step:=0;step<=iterations;step+=1{
        if !finite_c(z) do return {},false
        p,dp,ddp,scale:=evaluate(a,n,z)
        if !finite_c(p)||!finite_c(dp)||!finite_c(ddp)||!finite(scale) do return {},false
        if mag(p)<=tolerance*math.max(1.0,scale) do return z,true
        if step==iterations||(p.re==0&&p.im==0) do return {},false
        g:=divc(dp,p);h:=sub(mul(g,g),divc(ddp,p));rad:=mul(Cplx{f64(n-1),0},sub(mul(Cplx{f64(n),0},h),mul(g,g)))
        if !finite_c(g)||!finite_c(h)||!finite_c(rad) do return {},false
        root:=sqrt_c(rad);plus:=add(g,root);minus:=sub(g,root);den:=plus;if mag(minus)>mag(plus){den=minus}
        dm:=mag(den);if dm==0||!finite(dm) do return {},false
        correction:=divc(Cplx{f64(n),0},den);if !finite_c(correction) do return {},false
        z=sub(z,correction)
    }
    return {},false
}

@(export)
laguerre_complex_polynomial_root :: proc "c" (input:[^]f64,input_length:c.size_t,output:[^]f64,output_capacity:c.size_t)->i64{
    if input==nil||input_length<1||input_length>13 do return -1
    degree,ok:=integer_field(input[0],2,6);if !ok do return -1
    n:=int(degree);if input_length!=c.size_t(n+6) do return -1
    a:=[7]f64{}
    for i:=0;i<=n;i+=1{value,valid:=integer_field(input[1+i],-16,16);if !valid do return -1;a[i]=f64(value)}
    if a[n]==0 do return -1
    re,ok0:=integer_field(input[n+2],-4000,4000);im,ok1:=integer_field(input[n+3],-4000,4000)
    tolerance,ok2:=integer_field(input[n+4],1,1000);iterations,ok3:=integer_field(input[n+5],8,128)
    if !ok0||!ok1||!ok2||!ok3 do return -1
    if output==nil||output_capacity<2 do return -2
    root,ok:=solve(a,n,Cplx{f64(re)/1000,f64(im)/1000},f64(tolerance)/1_000_000,int(iterations))
    if !ok||!finite_c(root) do return -3
    output[0]=root.re;output[1]=root.im;return 2
}
