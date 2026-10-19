@export("and_gate")
fn and_gate(left: Int64, right: Int64) abi("C") -> Int64:
    return left & right
