@export("parity_check")
fn parity_check(x:Int64) abi("C")->Int64:
    if x < -2147483648 or x>2147483647:return -1
    var n=Int32(x);var p=0
    while n>0:p^=Int(n&1);n>>=1
    return 1 if p==0 else 0
