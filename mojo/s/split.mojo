from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("split")
fn split(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>259:return -1
    let textn=v[0];let sep=v[1]
    if textn<0 or textn>256 or sep<0 or sep>127 or n!=c_size_t(textn+2):return -1
    for i in range(Int(textn)):if v[i+2]<0 or v[i+2]>127:return -1
    if textn>0 and v[Int(textn)+1]==sep:return -1
    var seps=0
    for i in range(Int(textn)):if v[i+2]==sep:seps+=1
    if textn>0 and seps==0:return -1
    let fields=seps+1;let required=2+2*fields+Int(textn)-seps
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(required):return -2
    var result=InlineArray[UInt8,515](fill=0);result[0]=UInt8(fields&255);result[1]=UInt8((fields>>8)&255)
    var p=2;var start=0
    for i in range(Int(textn)+1):
        if i==Int(textn) or v[i+2]==sep:
            let fl=i-start;result[p]=UInt8(fl&255);result[p+1]=UInt8((fl>>8)&255);p+=2
            for j in range(start,i):result[p]=UInt8(v[j+2]);p+=1
            start=i+1
    for i in range(required):o[i]=result[i]
    return Int64(required)
