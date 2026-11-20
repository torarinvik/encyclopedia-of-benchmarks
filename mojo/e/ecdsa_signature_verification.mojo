from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ecdsa_mod(value:Int64,modulus:Int64)->Int64:
    let residue=value%modulus
    return residue+modulus if residue<0 else residue

fn ecdsa_inverse(value:Int64,modulus:Int64)->Int64:
    var old_r=modulus;var r=ecdsa_mod(value,modulus)
    var old_t:Int64=0;var t:Int64=1
    while r!=0:
        let quotient=old_r/r;let next_r=old_r-quotient*r;let next_t=old_t-quotient*t
        old_r=r;r=next_r;old_t=t;t=next_t
    return ecdsa_mod(old_t,modulus) if old_r==1 else 0

@fieldwise_init
struct EcdsaPoint:
    var infinity:Bool
    var x:Int64
    var y:Int64

fn ecdsa_infinity()->EcdsaPoint:return EcdsaPoint(infinity=True,x=0,y=0)

fn ecdsa_add(left:EcdsaPoint,right:EcdsaPoint)->EcdsaPoint:
    if left.infinity:return right
    if right.infinity:return left
    if left.x==right.x and ecdsa_mod(left.y+right.y,17)==0:return ecdsa_infinity()
    var numerator:Int64=0;var denominator:Int64=0
    if left.x==right.x and left.y==right.y:
        numerator=ecdsa_mod(3*left.x*left.x+2,17);denominator=ecdsa_mod(2*left.y,17)
    else:
        numerator=ecdsa_mod(right.y-left.y,17);denominator=ecdsa_mod(right.x-left.x,17)
    let slope=ecdsa_mod(numerator*ecdsa_inverse(denominator,17),17)
    let x=ecdsa_mod(slope*slope-left.x-right.x,17)
    let y=ecdsa_mod(slope*(left.x-x)-left.y,17)
    return EcdsaPoint(infinity=False,x=x,y=y)

fn ecdsa_multiply(point0:EcdsaPoint,scalar0:Int64)->EcdsaPoint:
    var point=point0;var scalar=scalar0;var result=ecdsa_infinity()
    while scalar>0:
        if scalar&1==1:result=ecdsa_add(result,point)
        scalar>>=1
        if scalar>0:point=ecdsa_add(point,point)
    return result

fn ecdsa_on_curve(point:EcdsaPoint)->Bool:
    return ecdsa_mod(point.y*point.y-point.x*point.x*point.x-2*point.x-2,17)==0

@export("ecdsa_signature_verification")
fn ecdsa_signature_verification(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,
    out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=11:return -1
    let p=v[0];let a=v[1];let b=v[2];let gx=v[3];let gy=v[4];let order=v[5]
    let qx=v[6];let qy=v[7];let digest=v[8];let r=v[9];let s=v[10]
    if p!=17 or a!=2 or b!=2 or gx!=5 or gy!=1 or order!=19:return -1
    if ecdsa_mod(4*a*a*a+27*b*b,p)==0 or qx<0 or qx>=p or qy<0 or qy>=p or digest<0 or digest>31 or r<1 or r>=order or s<1 or s>=order:return -1
    let base=EcdsaPoint(infinity=False,x=gx,y=gy);let public=EcdsaPoint(infinity=False,x=qx,y=qy)
    if not ecdsa_on_curve(base) or not ecdsa_on_curve(public) or not ecdsa_multiply(base,order).infinity or not ecdsa_multiply(public,order).infinity:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<1:return -2
    let w=ecdsa_inverse(s,order);if w==0:return -1
    let u1=digest*w%order;let u2=r*w%order
    let point=ecdsa_add(ecdsa_multiply(base,u1),ecdsa_multiply(public,u2))
    out[0]=UInt8(1 if not point.infinity and point.x%order==r else 0)
    return 1
