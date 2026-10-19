@export("double_factorial")
fn double_factorial(n:Int64) abi("C")->Int64:
    if n<0 or n>33:return -1
    var result:Int64=1;var factor=n
    while factor>1:result*=factor;factor-=2
    return result
