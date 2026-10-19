from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("maximum_ice_cream_bars")
fn maximum_ice_cream_bars(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or v[0]<0 or v[0]>1000000:return -1
    let count=Int(n)-1;var costs=InlineArray[Int64,256](fill=0)
    for i in range(count):
        let x=v[i+1];if x<1 or x>10000:return -1
        var j=i;while j>0 and costs[j-1]>x:costs[j]=costs[j-1];j-=1;costs[j]=x
    var remaining=v[0];var bought=0
    for i in range(count):if costs[i]>remaining:break;remaining-=costs[i];bought+=1
    return Int64(bought)
