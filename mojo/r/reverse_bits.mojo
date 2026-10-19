@export("reverse_bits")
fn reverse_bits(value:Int64) abi("C")->Int64:
    if value<0 or value>4294967295:return -1
    var x=UInt32(value);var result:UInt32=0
    for _ in range(32):result=(result<<1)|(x&UInt32(1));x=x>>1
    return Int64(result)
