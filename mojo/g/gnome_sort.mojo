from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("gnome_sort")
fn gnome_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n<2:return
    var pos=1
    while pos<n:
        if v[pos]>=v[pos-1]:pos+=1
        else:
            let temp=v[pos-1];v[pos-1]=v[pos];v[pos]=temp
            if pos>1:pos-=1
            else:pos=1
