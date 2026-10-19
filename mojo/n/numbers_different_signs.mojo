@export("numbers_different_signs")
fn numbers_different_signs(a:Int64,b:Int64) abi("C")->Int64:
    if a< -2147483648 or a>2147483647 or b< -2147483648 or b>2147483647:return -1
    return 1 if (Int32(a)^Int32(b))<0 else 0
