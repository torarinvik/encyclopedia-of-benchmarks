@export("power_of_four")
fn power_of_four(n:Int64) abi("C")->Int64:
    if n < -2147483648 or n > 2147483647:return -1
    if n<=0 or (n&(n-1))!=0:return 0
    return 1 if (n&0x55555555)!=0 else 0
