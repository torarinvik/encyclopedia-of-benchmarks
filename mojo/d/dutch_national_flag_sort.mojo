from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
fn dnf_swap(values:UnsafePointer[Int64,MutAnyOrigin],a:Int,b:Int):
    let t=values[a];values[a]=values[b];values[b]=t
@export("dutch_national_flag_sort")
fn dutch_national_flag_sort(values:UnsafePointer[Int64,MutAnyOrigin],length:c_size_t) abi("C"):
    var low=0;var middle=0;var high=Int(length)
    while middle<high:
        if values[middle]==0:dnf_swap(values,low,middle);low+=1;middle+=1
        elif values[middle]==1:middle+=1
        else:high-=1;dnf_swap(values,middle,high)
