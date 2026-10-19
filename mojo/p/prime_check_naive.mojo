@export("prime_check_naive")
fn prime_check_naive(n:Int64) abi("C")->Int64:
    if n>10000:return -1
    if n<2:return 0
    for d in range(2,Int(n)):
        if n%Int64(d)==0:return 0
    return 1
