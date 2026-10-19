from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("next_permutation")
fn next_permutation(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129:return -1
    let count=a[0]
    if count<0 or count>128 or n!=c_size_t(count+1):return -1
    var v=InlineArray[Int32,128]()
    for i in range(Int(count)):
        if a[i+1]< -2147483648 or a[i+1]>2147483647:return -1
        v[i]=Int32(a[i+1])
    var i=Int(count)-2
    while i>=0 and v[i]>=v[i+1]:i-=1
    if i>=0:
        var j=Int(count)-1
        while v[j]<=v[i]:j-=1
        let t=v[i];v[i]=v[j];v[j]=t
    var lo=i+1;var hi=Int(count)-1
    while lo<hi:
        let t=v[lo];v[lo]=v[hi];v[hi]=t;lo+=1;hi-=1
    let bytes=Int(count)*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for k in range(Int(count)):
        let bits=bitcast[UInt32](v[k])
        for b in range(4):o[k*4+b]=UInt8((bits>>UInt(8*b))&255)
    return count
