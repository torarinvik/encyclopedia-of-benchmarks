@export("power_of_two")
fn power_of_two(n:Int64) abi("C")->Int64:
    return 1 if n>0 and (n&(n-1))==0 else 0
