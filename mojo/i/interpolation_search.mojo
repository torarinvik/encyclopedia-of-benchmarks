from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("interpolation_search")
fn interpolation_search(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,target:Int64) abi("C")->Int64:
    if length==0:return -1
    var low=0;var high=Int(length)-1
    while low<=high:
        let lv=values[low];let hv=values[high]
        if target<lv or target>hv:return -1
        if lv==hv:return Int64(low) if lv==target else -1
        let numerator=(target-lv)*Int64(high-low);let denominator=hv-lv
        let pos=low+Int(numerator//denominator)
        let v=values[pos]
        if v==target:return Int64(pos)
        if v<target:low=pos+1
        else:
            if pos==0:return -1
            high=pos-1
    return -1
