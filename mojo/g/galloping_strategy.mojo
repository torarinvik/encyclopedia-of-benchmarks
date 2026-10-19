from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("galloping_strategy")
fn galloping_strategy(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>69:return -1
    let op=v[0];let count=v[1];let base=v[2];let length=v[3];let key=v[4]
    if (op!=0 and op!=1) or count<0 or count>64 or n!=c_size_t(5+count) or base<0 or length<0 or base>count or length>count-base or key< -2147483648 or key>2147483647:return -1
    if count==0:return 0
    if length==0 or base>=count:return -1
    for i in range(Int(count)):
        let x=v[5+i];if x< -2147483648 or x>2147483647:return -1
        if i>0 and i>base and i<base+length and v[5+i-1]>x:return -1
    var lo=Int(base);var hi=Int(base+length)
    while lo<hi:
        let mid=lo+(hi-lo)//2;let x=v[5+mid]
        if op==0:
            if x<key:lo=mid+1
            else:hi=mid
        else:
            if x<=key:lo=mid+1
            else:hi=mid
    return Int64(lo-Int(base))
