from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("maximum_bags_with_full_capacity")
fn maximum_bags_with_full_capacity(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>16384 or v[0]<0 or v[0]>1000000000 or v[1]<0 or v[1]>8191:return -1
    let count=Int(v[1]);if n!=c_size_t(2+2*count):return -1
    var deficits=InlineArray[Int64,8191](fill=0)
    for i in range(count):
        let cap=v[2+i];let rocks=v[2+count+i]
        if cap<1 or cap>100000 or rocks<0 or rocks>cap:return -1
        deficits[i]=cap-rocks
    for i in range(1,count):
        let x=deficits[i];var j=i
        while j>0 and deficits[j-1]>x:deficits[j]=deficits[j-1];j-=1
        deficits[j]=x
    var remaining=v[0];var full=0
    for i in range(count):
        if deficits[i]>remaining:break
        remaining-=deficits[i];full+=1
    return Int64(full)
