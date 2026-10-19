@export("xor_gate")
fn xor_gate(left:UInt64,right:UInt64) abi("C")->Int64:
    return Int64(left^right)
