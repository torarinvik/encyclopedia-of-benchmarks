@export("isautomorphic")
fn isautomorphic(n:Int64) abi("C")->Int64:
    if n< -3037000499 or n>3037000499:return -1
    if n<0:return 0
    let square=n*n;var remaining=n;var value=square
    while remaining>0:
        if remaining%10!=value%10:return 0
        remaining/=10;value/=10
    return 1
