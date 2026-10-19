from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("subset_combinations")
fn subset_combinations(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>13:return -1
    let choosev=v[0];let items=Int(n)-1
    if choosev<0 or items>12:return -1
    if choosev>items:return 0
    let k=Int(choosev);var count=1
    for i in range(1,k+1):count=count*(items-k+i)/i
    let bytes=count*2
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var ids=InlineArray[Int,12](fill=0)
    for i in range(k):ids[i]=i
    for comb in range(count):
        var mask=0
        for i in range(k):mask=mask|(1<<ids[i])
        o[2*comb]=UInt8(mask&255);o[2*comb+1]=UInt8((mask>>8)&255)
        if comb+1<count:
            var pos=k
            while pos>0:
                pos-=1
                if ids[pos]<items-k+pos:break
            ids[pos]+=1
            for i in range(pos+1,k):ids[i]=ids[i-1]+1
    return Int64(count)
