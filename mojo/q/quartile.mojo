from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("quartile")
fn quartile(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>11:return -1
    let count=a[0]
    if count<1 or count>10 or n!=c_size_t(count+1):return -1
    var v=InlineArray[Int64,10]()
    for i in range(Int(count)):
        if a[i+1]<0 or a[i+1]>99:return -1
        v[i]=a[i+1]
    for i in range(1,Int(count)):
        let x=v[i];var j=i
        while j>0 and v[j-1]>x:v[j]=v[j-1];j-=1
        v[j]=x
    let q1=v[Int(count)/4];let q3=v[(3*Int(count))/4];let words=Int(count)+4;let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var out=InlineArray[Int64,14]();out[0]=count
    for i in range(Int(count)):out[i+1]=v[i]
    out[Int(count)+1]=q1;out[Int(count)+2]=q3;out[Int(count)+3]=q3-q1
    for i in range(words):
        let bits=bitcast[UInt64](out[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
