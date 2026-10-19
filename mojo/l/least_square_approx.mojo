from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

fn round_scaled(a:Int64,b:Int64)->Int64:
    var q=(if a<0:-a else:a)*100000
    q=(q+b/2)/b
    return if a<0:-q else:q
@export("least_square_approx")
fn least_square_approx(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>13:return -1
    let k=v[0]
    if k<2 or k>6 or n!=c_size_t(1+2*k):return -1
    var sx:Int64=0;var sy:Int64=0;var sxx:Int64=0;var sxy:Int64=0
    for i in range(Int(k)):
        let x=v[1+2*i];let y=v[2+2*i]
        if x < -20 or x>20 or y < -20 or y>20:return -1
        sx+=x;sy+=y;sxx+=x*x;sxy+=x*y
    let den=k*sxx-sx*sx
    if den<=0:return -1
    let num=k*sxy-sx*sy;let slope=round_scaled(num,den);let intercept=round_scaled(sy*den-num*sx,k*den)
    let off=100000001;let radix=200000003
    if slope<=-off or slope>=off or intercept<=-off or intercept>=off:return -1
    return (slope+off)*radix+(intercept+off)
