fn add32(a:UInt32,b:UInt32)->UInt32:
    if b==0:return a
    return add32(a^b,(a&b)<<1)
@export("sum_without_arithmetic_operators")
fn sum_without_arithmetic_operators(a:Int64,b:Int64) abi("C")->Int64:
    if a< -2147483648 or a>2147483647 or b< -2147483648 or b>2147483647:return -2147483649
    let bits=add32(bitcast[UInt32](Int32(a)),bitcast[UInt32](Int32(b)))
    return Int64(bitcast[Int32](bits))
