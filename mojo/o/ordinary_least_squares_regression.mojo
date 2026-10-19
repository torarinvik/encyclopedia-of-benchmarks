from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn olsr_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let b=bitcast[UInt64](x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("ordinary_least_squares_regression")
fn ordinary_least_squares_regression(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>65 or v[0]<2 or v[0]>32 or n!=c_size_t(1+2*v[0]):return -1
    let count=Int(v[0]);var xs=InlineArray[Float64,32](fill=0.0);var ys=InlineArray[Float64,32](fill=0.0);var xm:Float64=0.0;var ym:Float64=0.0
    for i in range(count):
        let x=v[1+2*i];let y=v[2+2*i]
        if x < -10000 or x>10000 or y < -10000 or y>10000:return -1
        xs[i]=Float64(x);ys[i]=Float64(y);xm+=xs[i];ym+=ys[i]
    xm/=Float64(count);ym/=Float64(count);var numerator:Float64=0.0;var denominator:Float64=0.0
    for i in range(count):let dx=xs[i]-xm;numerator+=dx*(ys[i]-ym);denominator+=dx*dx
    if denominator==0:return -1
    let slope=numerator/denominator;let intercept=ym-slope*xm
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    olsr_put(o,0,intercept);olsr_put(o,8,slope);return 16
