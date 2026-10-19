from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("greedy_item_selection_by_value")
fn greedy_item_selection_by_value(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>18:return -1
    let capacity=v[0];let count=Int(v[1]);if capacity<0 or capacity>1000000 or count<0 or count>8 or n!=c_size_t(2+2*count):return -1
    var vals=InlineArray[Int64,8](fill=0);var weights=InlineArray[Int64,8](fill=0);var order=InlineArray[Int,8](fill=0)
    for i in range(count):
        vals[i]=v[2+i];weights[i]=v[2+count+i]
        if vals[i]<0 or vals[i]>1000000 or weights[i]<1 or weights[i]>1000000:return -1
        order[i]=i
    for i in range(1,count):
        let current=order[i];var pos=i
        while pos>0 and vals[order[pos-1]]<vals[current]:order[pos]=order[pos-1];pos-=1
        order[pos]=current
    var totalw:Int64=0;var totalv:Int64=0;var seq=UInt64(0);var selected=0
    for i in range(count):
        let item=order[i]
        if totalw+weights[item]<=capacity:
            seq|=UInt64(item+1)<<UInt64(4*selected);selected+=1;totalw+=weights[item];totalv+=vals[item]
    let packed=(UInt64(totalv)<<36)|(UInt64(selected)<<32)|seq
    return bitcast[Int64](packed)
