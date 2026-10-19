from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("sorted_arrays_intersection")
fn sorted_arrays_intersection(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>195:return -1
    var starts=InlineArray[Int,3](fill=0);var sizes=InlineArray[Int,3](fill=0);var p=0
    for arr in range(3):
        if p>=Int(n) or v[p]<0 or v[p]>64:return -1
        let sz=Int(v[p]);p+=1
        if sz>Int(n)-p:return -1
        starts[arr]=p;sizes[arr]=sz
        for i in range(sz):
            if v[p+i]< -2147483648 or v[p+i]>2147483647 or (i>0 and v[p+i-1]>=v[p+i]):return -1
        p+=sz
    if p!=Int(n):return -1
    let maxout=if sizes[0]<sizes[1] then (if sizes[0]<sizes[2] then sizes[0] else sizes[2]) else (if sizes[1]<sizes[2] then sizes[1] else sizes[2])
    if cap<c_size_t(maxout*4) or (maxout>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var cur=InlineArray[Int,3](fill=0);var outbuf=InlineArray[Int64,64](fill=0);var outn=0
    while cur[0]<sizes[0] and cur[1]<sizes[1] and cur[2]<sizes[2]:
        let a=v[starts[0]+cur[0]];let b=v[starts[1]+cur[1]];let c=v[starts[2]+cur[2]]
        if a==b and a==c:outbuf[outn]=a;outn+=1;cur[0]+=1;cur[1]+=1;cur[2]+=1
        elif a<b:cur[0]+=1
        elif b<c:cur[1]+=1
        else:cur[2]+=1
    for i in range(outn):
        let bits=bitcast[UInt32](Int32(outbuf[i]));for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(outn)
