@export("triangular_number")
fn triangular_number(n:Int64) abi("C")->Int64:
    if n<0 or n>4294967295:return -1
    let left=n/2 if (n&1)==0 else n
    let right=n+1 if (n&1)==0 else (n+1)/2
    return left*right
