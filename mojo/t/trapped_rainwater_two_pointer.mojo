from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("trapped_rainwater_two_pointer")
fn trapped_rainwater_two_pointer(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if a[i]<0 or a[i]>1000000:return -1
    if n<=2:return 0
    var left=0;var right=Int(n)-1;var lm:UInt32=0;var rm:UInt32=0;var trapped:UInt32=0
    while left<right:
        if a[left]<a[right]:
            let h=UInt32(a[left])
            if h>=lm:lm=h
            else:trapped+=lm-h
            left+=1
        else:
            let h=UInt32(a[right])
            if h>=rm:rm=h
            else:trapped+=rm-h
            right-=1
    return Int64(trapped)
