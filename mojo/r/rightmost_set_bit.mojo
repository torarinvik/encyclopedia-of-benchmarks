@export("rightmost_set_bit")
fn rightmost_set_bit(value:Int64) abi("C")->Int64:
    if value<=0 or value>2147483647:return -1
    var x=UInt32(value);var pos:Int64=1
    while (x&UInt32(1))==0:x=x>>1;pos+=1
    return pos
