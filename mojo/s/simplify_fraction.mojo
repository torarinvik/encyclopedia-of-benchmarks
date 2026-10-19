from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sf_gcd(a0:Int64,b0:Int64)->Int64:
    var a=abs(a0);var b=abs(b0);while b!=0:let r=a%b;a=b;b=r
    return a
@export("simplify_fraction")
fn simplify_fraction(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or a[0]< -1000000 or a[0]>1000000 or a[1]< -1000000 or a[1]>1000000 or a[1]==0:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    let g=sf_gcd(a[0],a[1]);var x=a[0]/g;var y=a[1]/g;if y<0:x= -x;y= -y
    let u=bitcast[UInt64](x);let v=bitcast[UInt64](y)
    for i in range(8):o[i]=UInt8((u>>UInt(8*i))&255);o[8+i]=UInt8((v>>UInt(8*i))&255)
    return 16
