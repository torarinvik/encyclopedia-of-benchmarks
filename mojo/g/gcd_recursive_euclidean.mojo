fn gcdr_step(a:UInt64,b:UInt64)->UInt64:
    if a==b:return a
    if a>b:return gcdr_step(a-b,b)
    return gcdr_step(a,b-a)
@export("gcd_recursive_euclidean")
fn gcd_recursive_euclidean(a:UInt64,b:UInt64) abi("C")->Int64:
    if a==0 or b==0 or a>128 or b>128:return -1
    return Int64(gcdr_step(a,b))
