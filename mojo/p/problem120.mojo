@export("problem120")
fn problem120(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>1000:return -1
    var total=Int64(0)
    for a in range(3,Int(limit+1)):total+=2*Int64(a)*(Int64(a-1)//2)
    return total
