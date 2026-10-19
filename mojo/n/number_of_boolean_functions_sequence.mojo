@export("number_of_boolean_functions_sequence")
fn number_of_boolean_functions_sequence(n:Int64) abi("C")->Int64:
    if n<0 or n>5:return -1
    var value:Int64=2
    for _ in range(Int(n)):value=value*value
    return value
