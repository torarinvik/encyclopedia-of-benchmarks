@export("natural_sequence")
fn natural_sequence(x:Int64) abi("C")->Int64:
    if x<0 or x==9223372036854775807:return -1
    return x+1
