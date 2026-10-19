from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn isr_prefix(values:UnsafePointer[Int64,MutAnyOrigin],length:Int):
    if length<=1:return
    isr_prefix(values,length-1)
    let key=values[length-1];var pos=length-1
    while pos>0 and values[pos-1]>key:values[pos]=values[pos-1];pos-=1
    values[pos]=key

@export("insertion_sort_recursive")
fn insertion_sort_recursive(values:UnsafePointer[Int64,MutAnyOrigin],length:c_size_t) abi("C"):
    isr_prefix(values,Int(length))
