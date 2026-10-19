from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("windowed_median")
fn windowed_median(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>130:return -1
    let w=a[0];let count=a[1]
    if w<1 or w>64 or count<1 or count>128 or n!=c_size_t(count+2):return -1
    for i in range(Int(count)):if a[i+2]< -1000000 or a[i+2]>1000000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    var sorted=InlineArray[Int64,64]();var active=0
    for i in range(Int(count)):
        if i>=Int(w):
            let old=a[i+2-Int(w)];var p=0
            while p<active and sorted[p]!=old:p+=1
            if p>=active:return -1
            for j in range(p+1,active):sorted[j-1]=sorted[j]
            active-=1
        let value=a[i+2];var p=0
        while p<active and sorted[p]<value:p+=1
        var j=active
        while j>p:sorted[j]=sorted[j-1];j-=1
        sorted[p]=value;active+=1
        var median:Float32
        if active%2==1:median=Float32(sorted[active/2])
        else:median=0.5*Float32(sorted[active/2-1])+0.5*Float32(sorted[active/2])
        let bits=bitcast[UInt64](Float64(median));for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(count*8)
