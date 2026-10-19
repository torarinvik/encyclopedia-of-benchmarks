@export("powers_of2_sequence")
fn powers_of2_sequence(n:Int64) abi("C")->Int64:
    if n<0 or n>62:return -1
    var value=Int64(1)
    for _ in range(Int(n)):value*=2
    return value
