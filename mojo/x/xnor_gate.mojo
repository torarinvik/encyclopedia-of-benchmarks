@export("xnor_gate")
fn xnor_gate(left:UInt64,right:UInt64) abi("C")->Int64:
    return Int64(1-(left^right))
