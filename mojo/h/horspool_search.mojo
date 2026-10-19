from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("horspool_search")
fn horspool_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>578:return -2
    let tn=a[0];let pn=a[1]
    if tn<0 or tn>512 or pn<0 or pn>64 or n!=c_size_t(2+tn+pn):return -2
    for i in range(Int(tn)+Int(pn)):
        let c=a[2+i];if c<0 or c>127:return -2
    if pn==0:return -1
    if pn>tn:return -1
    var shift=InlineArray[Int,128](fill=Int(pn))
    for i in range(Int(pn)-1):shift[Int(a[2+Int(tn)+i])]=Int(pn)-1-i
    var pos=0
    while pos<=Int(tn-pn):
        var j=Int(pn)-1
        while j>=0 and a[2+pos+j]==a[2+Int(tn)+j]:j-=1
        if j<0:return Int64(pos)
        pos+=shift[Int(a[2+pos+Int(pn)-1])]
    return -1
