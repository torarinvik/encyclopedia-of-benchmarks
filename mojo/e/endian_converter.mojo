@export("endian_converter")
fn endian_converter(value:Int64) abi("C")->Int64:
    if value< -2147483648 or value>2147483647:return -2147483649
    let bits=UInt32(value)
    let reversed=((bits&255)<<24)|((bits&65280)<<8)|((bits>>8)&65280)|(bits>>24)
    return Int64(bitcast[Int32](reversed))
