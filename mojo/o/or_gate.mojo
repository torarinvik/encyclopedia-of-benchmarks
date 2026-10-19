@export("or_gate")
fn or_gate(left:UInt64,right:UInt64) abi("C")->Int64:
    return bitcast[Int64](left|right)
