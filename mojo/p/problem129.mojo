fn p129_repunit(divisor:Int64)->Int64:
    if divisor%5==0 or divisor%2==0:return 0
    var r=Int64(1);var length=Int64(1)
    while r!=0:r=(10*r+1)%divisor;length+=1
    return length
@export("problem129")
fn problem129(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>1000000:return -1
    var divisor=limit-1
    if divisor%2==0:divisor+=1
    while p129_repunit(divisor)<=limit:divisor+=2
    return divisor
