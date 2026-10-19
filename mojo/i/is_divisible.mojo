@export("is_divisible")
fn is_divisible(dividend:UInt64,divisor:UInt64) abi("C")->Int64:
    if dividend>1000000000 or divisor==0 or divisor>1000000000:return -1
    return 1 if dividend%divisor==0 else 0
