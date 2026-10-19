@export("hamming_weight")
fn hamming_weight(value:Int64) abi("C")->Int64:
    if value<0 or value>4294967295:return -1
    var n=UInt64(value);var count=0
    for i in range(32):count+=Int(n&1);n>>=1
    return count
