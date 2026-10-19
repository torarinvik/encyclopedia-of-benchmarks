@export("powers_of10_sequence")
fn powers_of10_sequence(n:Int64) abi("C")->Int64:
    if n<0 or n>18:return -1
    var value=Int64(1)
    for _ in range(Int(n)):value*=10
    return value
