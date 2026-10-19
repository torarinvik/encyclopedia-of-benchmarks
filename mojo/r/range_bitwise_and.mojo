@export("range_bitwise_and")
fn range_bitwise_and(left:UInt64,right:UInt64) abi("C")->Int64:
    if left>right or right>2147483647:return -1
    var r=right
    while left<r:r&=r-1
    return Int64(r)
