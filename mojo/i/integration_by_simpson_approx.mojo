from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor

fn simpson_round(x:Float64,p:Int)->Float64:
    var scale=1.0
    for _ in range(p):scale*=10.0
    let y=x*scale;var lo=floor(y);let frac=y-lo
    if frac>0.5 or (frac==0.5 and Int64(lo)%2!=0):lo+=1.0
    return lo/scale

@export("integration_by_simpson_approx")
fn integration_by_simpson_approx(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1.0e300
    let a=input[0];let b=input[1];let p=input[2]
    if a< -10 or a>10 or b< -10 or b>10 or a>=b or p<0 or p>4:return -1.0e300
    let h=Float64(b-a)/1000.0
    var total=Float64(a*a)+Float64(b*b)
    for i in range(1,1000):
        let x=Float64(a)+h*Float64(i)
        total+=x*x*(4.0 if i%2==1 else 2.0)
    total*=h/3.0
    return simpson_round(total,Int(p))
