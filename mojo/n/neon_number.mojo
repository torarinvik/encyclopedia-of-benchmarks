@export("neon_number")
fn neon_number(n:Int64) abi("C")->Int64:
    if n<0:return 0
    if n>3000000000:return -1
    var v=n*n;var sum:Int64=0
    while v>0:sum+=v%10;v//=10
    return 1 if sum==n else 0
