@export("zero_sequence")
fn zero_sequence(index:Int64) abi("C")->Int64:
    return -1 if index<0 else 0
