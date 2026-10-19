from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("max_product_of_three")
fn max_product_of_three(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<3 or v[0]>128 or n!=c_size_t(v[0]+1):return -9223372036854775808
    let count=Int(v[0])
    for i in range(count):if v[i+1]< -1000 or v[i+1]>1000:return -9223372036854775808
    var max1=v[1];var max2:Int64= -1001;var max3:Int64= -1001;var min1=v[1];var min2:Int64=1001
    for i in range(1,count):
        let x=v[i+1]
        if x>max1:max3=max2;max2=max1;max1=x
        elif x>max2:max3=max2;max2=x
        elif x>max3:max3=x
        if x<min1:min2=min1;min1=x
        elif x<min2:min2=x
    let p1=max1*max2*max3;let p2=max1*min1*min2
    return p1 if p1>p2 else p2
