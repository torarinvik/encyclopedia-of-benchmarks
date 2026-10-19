from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lcp_compare(v:UnsafePointer[Int64,ImmutAnyOrigin],sa:Int,la:Int,sb:Int,lb:Int)->Int:
    let lim=min(la,lb)
    for i in range(lim):
        if v[sa+i]<v[sb+i]:return -1
        if v[sa+i]>v[sb+i]:return 1
    return if la<lb:-1 elif la>lb:1 else:0
@export("longest_common_prefix")
fn longest_common_prefix(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1041 or v[0]<0 or v[0]>16:return -1
    let count=Int(v[0]);var starts=InlineArray[Int64,16](fill=0);var sizes=InlineArray[Int64,16](fill=0);var pos=1
    for i in range(count):
        if pos>=Int(n) or v[pos]<0 or v[pos]>64:return -1
        let len=Int(v[pos]);pos+=1
        if len>Int(n)-pos:return -1
        starts[i]=Int64(pos);sizes[i]=Int64(len)
        for j in range(len):
            if v[pos+j]<0 or v[pos+j]>127:return -1
        pos+=len
    if pos!=Int(n):return -1
    if count==0:return 0
    var order=InlineArray[Int64,16](fill=0)
    for i in range(count):order[i]=Int64(i)
    for i in range(1,count):
        let x=order[i];var j=i
        while j>0 and lcp_compare(v,Int(starts[order[j-1]]),Int(sizes[order[j-1]]),Int(starts[x]),Int(sizes[x]))>0:order[j]=order[j-1];j-=1
        order[j]=x
    let first=Int(order[0]);let last=Int(order[count-1]);let limit=min(Int(sizes[first]),Int(sizes[last]));var prefix=0
    while prefix<limit and v[Int(starts[first])+prefix]==v[Int(starts[last])+prefix]:prefix+=1
    if cap<c_size_t(prefix) or (prefix!=0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(prefix):out[i]=UInt8(v[Int(starts[first])+i])
    return Int64(prefix)
