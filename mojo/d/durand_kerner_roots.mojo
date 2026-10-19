from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import sqrt
struct DKComplex:
    var re:Float64
    var im:Float64
    fn __init__(out self,re:Float64,im:Float64):
        self.re=re;self.im=im
fn dk_sub(a:DKComplex,b:DKComplex)->DKComplex:return DKComplex(a.re-b.re,a.im-b.im)
fn dk_mul(a:DKComplex,b:DKComplex)->DKComplex:return DKComplex(a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re)
fn dk_div(a:DKComplex,b:DKComplex)->DKComplex:
    let den=b.re*b.re+b.im*b.im
    return DKComplex((a.re*b.re+a.im*b.im)/den,(a.im*b.re-a.re*b.im)/den)
@export("durand_kerner_roots")
fn durand_kerner_roots(v:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3 or v[0]==0 or v[0]< -4 or v[0]>4 or v[1]<0 or v[1]>2 or v[2]<0 or v[2]>1:return -1.0e300
    let sign=1.0 if v[0]>0 else -1.0;let q=sqrt(3.0)/2.0;var z=List[DKComplex](capacity=3)
    z.append(DKComplex(sign,0.0));z.append(DKComplex(sign* -0.5,sign*q));z.append(DKComplex(sign* -0.5,sign* -q))
    for it in range(100):
        var next=List[DKComplex](capacity=3);var change:Float64=0.0
        for i in range(3):
            var den=DKComplex(1.0,0.0)
            for j in range(3):
                if i!=j:den=dk_mul(den,dk_sub(z[i],z[j]))
            let cube=dk_mul(dk_mul(z[i],z[i]),z[i]);let numerator=DKComplex(cube.re-Float64(v[0]),cube.im);let updated=dk_sub(z[i],dk_div(numerator,den));next.append(updated)
            let dr=updated.re-z[i].re;let di=updated.im-z[i].im;let delta=sqrt(dr*dr+di*di)
            if delta>change:change=delta
        z=next
        if change<1.0e-14:break
    let root=z[Int(v[1])]
    return root.re if v[2]==0 else root.im
