@export("signum")
fn signum(x:Int64) abi("C")->Int64:
    if x<0:return -1
    if x>0:return 1
    return 0
