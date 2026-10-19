from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("insertion_sort")
fn insertion_sort(values:UnsafePointer[Int64,MutAnyOrigin],length:c_size_t) abi("C"):
    for i in range(1,Int(length)):
        let key=values[i];var pos=i
        while pos>0 and values[pos-1]>key:values[pos]=values[pos-1];pos-=1
        values[pos]=key
