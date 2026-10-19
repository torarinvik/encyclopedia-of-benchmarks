from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ec_mod(x:Int64,p:Int64)->Int64:
    let r=x%p
    return r+p if r<0 else r
fn ec_prime(p:Int64)->Bool:
    if p<2:return False
    for d in range(2,Int(p)):
        if Int64(d)*Int64(d)>p:break
        if p%Int64(d)==0:return False
    return True
fn ec_pow(base0:Int64,exponent0:Int64,p:Int64)->Int64:
    var base=ec_mod(base0,p);var exponent=exponent0;var result:Int64=1
    while exponent>0:
        if exponent&1==1:result=result*base%p
        base=base*base%p;exponent>>=1
    return result
@fieldwise_init
struct EcPoint:
    var infinity:Bool
    var x:Int64
    var y:Int64
fn ec_add(p:Int64,a:Int64,u:EcPoint,v:EcPoint)->EcPoint:
    if u.infinity:return v
    if v.infinity:return u
    if u.x==v.x and ec_mod(u.y+v.y,p)==0:return EcPoint(infinity=True,x=0,y=0)
    var slope:Int64=0
    if u.x==v.x and u.y==v.y:slope=ec_mod((3*u.x*u.x+a)*ec_pow(2*u.y,p-2,p),p)
    else:slope=ec_mod((v.y-u.y)*ec_pow(v.x-u.x,p-2,p),p)
    let x=ec_mod(slope*slope-u.x-v.x,p);let y=ec_mod(slope*(u.x-x)-u.y,p)
    return EcPoint(infinity=False,x=x,y=y)
fn ec_mul(p:Int64,a:Int64,point:EcPoint,k0:Int64)->EcPoint:
    var result=EcPoint(infinity=True,x=0,y=0);var base=point;var k=k0
    while k>0:
        if k&1==1:result=ec_add(p,a,result,base)
        k>>=1
        if k>0:base=ec_add(p,a,base,base)
    return result
fn ec_put(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for i in range(8):output[offset+i]=UInt8((bits>>UInt(8*i))&255)
@export("elliptic_curve_key_exchange")
fn elliptic_curve_key_exchange(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=7:return -1
    let p=v[0];let a=v[1];let b=v[2];let x=v[3];let y=v[4];let ka=v[5];let kb=v[6]
    if p<5 or p>251 or not ec_prime(p) or a<0 or a>=p or b<0 or b>=p or x<0 or x>=p or y<0 or y>=p or ka<1 or ka>1024 or kb<1 or kb>1024:return -1
    if ec_mod(4*a*a*a+27*b*b,p)==0 or ec_mod(y*y-x*x*x-a*x-b,p)!=0:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<48:return -2
    let g=EcPoint(infinity=False,x=x,y=y);let alice=ec_mul(p,a,g,ka);let bob=ec_mul(p,a,g,kb)
    let shared=ec_mul(p,a,alice,kb);let check=ec_mul(p,a,bob,ka)
    if shared.infinity!=check.infinity or (not shared.infinity and (shared.x!=check.x or shared.y!=check.y)):return -1
    ec_put(out,0, -1 if alice.infinity else alice.x);ec_put(out,8, -1 if alice.infinity else alice.y)
    ec_put(out,16, -1 if bob.infinity else bob.x);ec_put(out,24, -1 if bob.infinity else bob.y)
    ec_put(out,32, -1 if shared.infinity else shared.x);ec_put(out,40, -1 if shared.infinity else shared.y)
    return 48
