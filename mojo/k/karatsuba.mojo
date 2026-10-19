from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn karatsuba_mul(x:Int64,y:Int64)->Int64:
    if x<10 or y<10:return x*y
    var m=max(x,y);var digits=1
    while m>=10:m//=10;digits+=1
    var split:Int64=1
    for _ in range(digits//2):split*=10
    let xh=x//split;let xl=x%split;let yh=y//split;let yl=y%split
    let z0=karatsuba_mul(xl,yl);let z2=karatsuba_mul(xh,yh);let z1=karatsuba_mul(xh+xl,yh+yl)
    return z2*split*split+(z1-z2-z0)*split+z0
@export("karatsuba")
fn karatsuba(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    if a[0]<0 or a[0]>1000000 or a[1]<0 or a[1]>1000000:return -1
    return karatsuba_mul(a[0],a[1])
