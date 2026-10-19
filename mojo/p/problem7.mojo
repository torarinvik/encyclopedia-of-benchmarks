fn p7_prime(value:Int64)->Bool:
    if value<2:return False
    var factor=Int64(2)
    while factor<=value//factor:
        if value%factor==0:return False
        factor+=1
    return True
@export("problem7")
fn problem7(index:Int64) abi("C")->Int64:
    if index<1 or index>10001:return -1
    var count=Int64(0);var candidate=Int64(1)
    while count<index:
        candidate+=1
        if p7_prime(candidate):count+=1
    return candidate
