from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("union_of_two_arrays")
fn union_of_two_arrays(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let aN=v[0]
    if aN<0 or aN>64 or n<c_size_t(2+aN):return -1
    let bpos=1+Int(aN)
    let bN=v[bpos]
    if bN<0 or bN>64 or n!=c_size_t(bpos+1+bN):return -1
    for i in range(Int(aN)+Int(bN)):
        let val=v[1+i] if i<Int(aN) else v[bpos+1+i-Int(aN)]
        if val < -2147483648 or val > 2147483647:return -1
    for i in range(1,Int(aN)):
        if v[i]>v[i+1]:return -1
    for i in range(1,Int(bN)):
        if v[bpos+i]>v[bpos+i+1]:return -1
    var merged=InlineArray[Int64,128](fill=0);var used=0;var i=0;var j=0
    while i<Int(aN) or j<Int(bN):
        var x:Int64
        if j>=Int(bN) or (i<Int(aN) and v[1+i]<v[bpos+1+j]):x=v[1+i];i+=1
        elif i>=Int(aN) or v[bpos+1+j]<v[1+i]:x=v[bpos+1+j];j+=1
        else:x=v[1+i];i+=1;j+=1
        if used==0 or merged[used-1]!=x:merged[used]=x;used+=1
    if cap<c_size_t(4*(Int(aN)+Int(bN))):return -2
    if used>0 and o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for k in range(used):
        for b in range(4):o[k*4+b]=UInt8((merged[k]>>(8*b))&255)
    return Int64(used)
