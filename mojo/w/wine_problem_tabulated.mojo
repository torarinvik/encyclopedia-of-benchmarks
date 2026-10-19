from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("wine_problem_tabulated")
fn wine_problem_tabulated(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    for i in range(Int(n)):if a[i]<0 or a[i]>1000000:return -1
    var table=InlineArray[Int64,4096]()
    for width in range(1,Int(n)+1):
        let year=Int(n)-width+1
        for first in range(0,Int(n)-width+1):
            let last=first+width-1;let slot=first*64+last
            if first==last:table[slot]=a[first]*Int64(year)
            else:
                let x=a[first]*Int64(year)+table[(first+1)*64+last]
                let y=a[last]*Int64(year)+table[first*64+last-1]
                table[slot]=max(x,y)
    return table[Int(n)-1]
