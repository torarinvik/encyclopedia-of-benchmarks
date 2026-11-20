from std.ffi import c_size_t
from std.math import isfinite, sqrt, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

struct C:
    var re: Float64
    var im: Float64
    fn __init__(out self,re:Float64,im:Float64):
        self.re=re;self.im=im

fn c_add(a:C,b:C)->C:return C(a.re+b.re,a.im+b.im)
fn c_sub(a:C,b:C)->C:return C(a.re-b.re,a.im-b.im)
fn c_mul(a:C,b:C)->C:return C(a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re)
fn c_div(a:C,b:C)->C:
    let den=b.re*b.re+b.im*b.im
    return C((a.re*b.re+a.im*b.im)/den,(a.im*b.re-a.re*b.im)/den)
fn c_abs(a:C)->Float64:return sqrt(a.re*a.re+a.im*a.im)
fn finite_c(a:C)->Bool:return isfinite(a.re) and isfinite(a.im)
fn c_sqrt(a:C)->C:
    let m=c_abs(a)
    let re=sqrt(max(0.0,(m+a.re)*0.5))
    var im=sqrt(max(0.0,(m-a.re)*0.5))
    if a.im<0.0:im = -im
    return C(re,im)
fn integer_field(x:Float64,lo:Int64,hi:Int64)->(Int64,Bool):
    if not isfinite(x) or x<Float64(lo) or x>Float64(hi) or trunc(x)!=x:return (0,False)
    return (Int64(x),True)
fn evaluate(a:List[Float64],n:Int,z:C)->(C,C,C,Float64):
    var p=C(a[n],0.0);var dp=C(0.0,0.0);var ddp=C(0.0,0.0)
    for k in range(n-1,-1,-1):
        ddp=c_add(c_mul(ddp,z),C(2.0*dp.re,2.0*dp.im))
        dp=c_add(c_mul(dp,z),p)
        p=c_add(c_mul(p,z),C(a[k],0.0))
    let radius=c_abs(z);var scale=abs(a[n])
    for k in range(n-1,-1,-1):scale=scale*radius+abs(a[k])
    return (p,dp,ddp,scale)
fn solve(a:List[Float64],n:Int,start:C,tolerance:Float64,iterations:Int)->(Int64,C):
    var z=start
    for step in range(iterations+1):
        if not finite_c(z):return (-3,C(0.0,0.0))
        let (p,dp,ddp,scale)=evaluate(a,n,z)
        if not finite_c(p) or not finite_c(dp) or not finite_c(ddp) or not isfinite(scale):return (-3,C(0.0,0.0))
        if c_abs(p)<=tolerance*max(1.0,scale):return (2,z)
        if step==iterations or (p.re==0.0 and p.im==0.0):return (-3,C(0.0,0.0))
        let g=c_div(dp,p)
        let h=c_sub(c_mul(g,g),c_div(ddp,p))
        let rad=c_mul(C(Float64(n-1),0.0),c_sub(c_mul(C(Float64(n),0.0),h),c_mul(g,g)))
        if not finite_c(g) or not finite_c(h) or not finite_c(rad):return (-3,C(0.0,0.0))
        let root=c_sqrt(rad);let plus=c_add(g,root);let minus=c_sub(g,root)
        let den=plus if c_abs(plus)>=c_abs(minus) else minus
        let dm=c_abs(den)
        if dm==0.0 or not isfinite(dm):return (-3,C(0.0,0.0))
        let correction=c_div(C(Float64(n),0.0),den)
        if not finite_c(correction):return (-3,C(0.0,0.0))
        z=c_sub(z,correction)
    return (-3,C(0.0,0.0))

@export("laguerre_complex_polynomial_root")
fn laguerre_complex_polynomial_root(input:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,
    output:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length<1 or length>13:return -1
    let (degree,degree_ok)=integer_field(input[0],2,6)
    if not degree_ok:return -1
    let n=Int(degree)
    if length!=c_size_t(n+6):return -1
    var a=List[Float64](capacity=n+1)
    for i in range(n+1):
        let (value,ok)=integer_field(input[1+i],-16,16)
        if not ok:return -1
        a.append(Float64(value))
    if a[n]==0.0:return -1
    let (re,re_ok)=integer_field(input[n+2],-4000,4000)
    let (im,im_ok)=integer_field(input[n+3],-4000,4000)
    let (tol,tol_ok)=integer_field(input[n+4],1,1000)
    let (iterations,iterations_ok)=integer_field(input[n+5],8,128)
    if not re_ok or not im_ok or not tol_ok or not iterations_ok:return -1
    if output==UnsafePointer[Float64,MutAnyOrigin]() or capacity<2:return -2
    let (status,root)=solve(a,n,C(Float64(re)/1000.0,Float64(im)/1000.0),Float64(tol)/1_000_000.0,Int(iterations))
    if status!=2 or not finite_c(root):return -3
    output[0]=root.re;output[1]=root.im
    return 2
