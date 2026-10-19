from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn iir_store(out:UnsafePointer[UInt8,MutAnyOrigin],idx:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[idx*8+b]=UInt8((bits>>(8*b))&255)

@export("iir_filter")
fn iir_filter(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
              output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<7 or length>26 or input[0]<1 or input[0]>3 or input[1]<1 or input[1]>16:return -1
    let order=Int(input[0]);let samples=Int(input[1])
    if Int(length)!=4+2*order+samples:return -1
    var a=InlineArray[Float64,4](fill=0.0);var b=InlineArray[Float64,4](fill=0.0)
    for i in range(order+1):
        let av=input[2+i];let bv=input[3+order+i]
        if av< -500 or av>2000 or bv< -500 or bv>500:return -1
        a[i]=Float64(av)/1000.0;b[i]=Float64(bv)/1000.0
    if a[0]<0.5:return -1
    for i in range(samples):
        if input[4+2*order+i]< -1000 or input[4+2*order+i]>1000:return -1
    let bytes=samples*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    var xh=InlineArray[Float64,3](fill=0.0);var yh=InlineArray[Float64,3](fill=0.0)
    for sample in range(samples):
        let x=Float64(input[4+2*order+sample])/1000.0
        var result=0.0
        for i in range(1,order+1):result+=b[i]*xh[i-1]-a[i]*yh[i-1]
        result=(result+b[0]*x)/a[0]
        var i=order-1
        while i>0:xh[i]=xh[i-1];yh[i]=yh[i-1];i-=1
        xh[0]=x;yh[0]=result
        iir_store(output,sample,result)
    return Int64(bytes)
