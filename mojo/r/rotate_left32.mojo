@export("rotate_left32")
fn rotate_left32(value:UInt64,shift:UInt64) abi("C")->Int64:
    if value>UInt64(4294967295) or shift>UInt64(2147483647):return -1
    let s=UInt32(shift%32);let x=UInt32(value)
    if s==0:return Int64(x)
    return Int64((x<<s)|(x>>(32-s)))
