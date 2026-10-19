from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("optimal_file_merging")
fn optimal_file_merging(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>33 or v[0]<0 or v[0]>32 or n!=c_size_t(v[0]+1):return -1
    var a=InlineArray[Int64,32](fill=0);let count=Int(v[0])
    for i in range(count):if v[i+1]<0 or v[i+1]>1000000:return -1;a[i]=v[i+1]
    var used=count;var total:Int64=0
    while used>1:
        var ia=0;var ib=1
        if a[ib]<a[ia]:let t=ia;ia=ib;ib=t
        for i in range(2,used):
            if a[i]<a[ia]:ib=ia;ia=i
            elif a[i]<a[ib]:ib=i
        let merged=a[ia]+a[ib];total+=merged
        if ia>ib:let t=ia;ia=ib;ib=t
        a[ia]=merged;a[ib]=a[used-1];used-=1
    return total
