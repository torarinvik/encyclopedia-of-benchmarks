from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("streaming_moving_average")
fn streaming_moving_average(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let wv=v[0];let cv=v[1]
    if wv<1 or wv>256 or cv<1 or cv>256 or n!=c_size_t(cv+2):return -1
    let count=Int(cv);let window=Int(wv)
    for i in range(count):if v[2+i]< -2147483648 or v[2+i]>2147483647:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    var result=InlineArray[Float64,256](fill=0.0)
    for i in range(count):
        let start=if i+1>window then i+1-window else 0;var sum:Int64=0
        for j in range(start,i+1):sum+=v[2+j]
        result[i]=Float64(sum)/Float64(i+1-start)
    for i in range(count):let bits=bitcast[UInt64](result[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(count*8)
