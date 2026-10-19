@export("next_power_of_two")
fn next_power_of_two(n:Int64) abi("C")->Int64:
    if n<1 or n>1073741824:return -1
    var p:Int64=1
    while p<n:p*=2
    return p
