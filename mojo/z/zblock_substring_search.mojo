from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("zblock_substring_search")
fn zblock_substring_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>322:return -1
    let tl=v[0];let pl=v[1]
    if tl<0 or tl>256 or pl<1 or pl>64 or n!=c_size_t(tl+pl+2):return -1
    for i in range(2,Int(n)):if v[i]<0 or v[i]>127 or v[i]==36:return -1
    let total=Int(tl+pl+1);let sep=Int(pl)
    var seq=InlineArray[Int64,321](fill=0);var z=InlineArray[Int,321](fill=0)
    for i in range(sep):seq[i]=v[2+Int(tl)+i]
    seq[sep]= -1
    for i in range(Int(tl)):seq[sep+1+i]=v[2+i]
    var left=0;var right=0
    for i in range(1,total):
        if i<=right:z[i]=min(right-i+1,z[i-left])
        while i+z[i]<total and seq[z[i]]==seq[i+z[i]]:z[i]+=1
        if i+z[i]-1>right:left=i;right=i+z[i]-1
    var found=0
    for i in range(sep+1,total):if z[i]>=sep:found+=1
    return Int64(found)
