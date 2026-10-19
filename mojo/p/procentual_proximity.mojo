from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("procentual_proximity")
fn procentual_proximity(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>642:return -1
    let rows=input[0];let cols=input[1]
    if rows<1 or rows>64 or cols<1 or cols>8 or length!=c_size_t(2+cols+rows*cols):return -1
    for c in range(Int(cols)):if input[2+c]!=0 and input[2+c]!=1:return -1
    var data=InlineArray[Float64,512](fill=0);var minima=InlineArray[Int64,8](fill=0);var maxima=InlineArray[Int64,8](fill=0)
    for c in range(Int(cols)):minima[c]=10001;maxima[c]= -10001
    for r in range(Int(rows)):
        for c in range(Int(cols)):
            let value=input[2+Int(cols)+r*Int(cols)+c]
            if value< -10000 or value>10000:return -1
            data[r*Int(cols)+c]=Float64(value)
            if value<minima[c]:minima[c]=value
            if value>maxima[c]:maxima[c]=value
    let bytes=Int(rows)*(Int(cols)+1)*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for r in range(Int(rows)):
        var score=Float64(0.0)
        for c in range(Int(cols)):
            let span=maxima[c]-minima[c];var normalized=Float64(0.0)
            if span==0:
                normalized=1.0 if input[2+c]==0 else 0.0
            else:
                normalized=(data[r*Int(cols)+c]-Float64(minima[c]))/Float64(span)
                if input[2+c]==0:normalized=1.0-normalized
            score+=normalized
        for c in range(Int(cols)+1):
            let value=data[r*Int(cols)+c] if c<Int(cols) else score
            let bits=bitcast[UInt64](value)
            for b in range(8):output[(r*(Int(cols)+1)+c)*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
