@export("max_value")
fn max_value(a:Int64,b:Int64) abi("C")->Int64:
    if a< -2147483648 or a>2147483647 or b< -2147483648 or b>2147483647:return -1
    return a if a>=b else b
