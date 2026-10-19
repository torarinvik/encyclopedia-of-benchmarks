@export("byte_encoding_utils")
fn byte_encoding_utils(value: Int64) abi("C") -> Int64:
    let bits=bitcast[UInt64](value)
    var reversed:UInt64=0
    for i in range(8): reversed |= ((bits>>(8*i))&255)<<(8*(7-i))
    return bitcast[Int64](reversed)
