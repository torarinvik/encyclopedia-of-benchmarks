@export("swap_adjacent_bits")
fn swap_adjacent_bits(input:Int64) abi("C")->Int64:
    if input<0 or input>1073741823:return -1
    let value=UInt32(input)
    return Int64(((value&UInt32(0xAAAAAAAA))>>1)|((value&UInt32(0x55555555))<<1))
