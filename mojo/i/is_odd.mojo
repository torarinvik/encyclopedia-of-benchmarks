@export("is_odd")
fn is_odd(value:Int64) abi("C")->Int64:return 1 if value%2!=0 else 0
