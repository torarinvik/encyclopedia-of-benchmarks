from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("quick_search")
fn quick_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512:return -1
    let tl=a[0];let pl=a[1]
    if tl<0 or tl>255 or pl<0 or pl>255 or n!=c_size_t(2+tl+pl):return -1
    for i in range(Int(tl+pl)):if a[i+2]<0 or a[i+2]>127:return -1
    if pl==0:return 0
    if pl>tl:return -1
    var shift=InlineArray[Int64,128](fill=Int64(pl))
    for i in range(Int(pl)):shift[Int(a[2+tl+i])]=pl-Int64(i)
    var pos=0
    while pos+Int(pl)<=Int(tl):
        var j=Int(pl)-1
        while j>=0 and a[2+pos+j]==a[2+Int(tl)+j]:j-=1
        if j<0:return pos
        if pos+Int(pl)<Int(tl):pos+=Int(shift[Int(a[2+pos+Int(pl)])])
        else:break
    return -1
