@export("highest_set_bit")
fn highest_set_bit(value:Int64) abi("C")->Int64:
    if value<=0:return -1
    var x=UInt64(value);var index:Int64=0
    while x>1:x>>=1;index+=1
    return index
