@export("problem1")
fn problem1(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>100000:return -1
    var sum=Int64(0)
    for x in range(1,Int(limit)):if x%3==0 or x%5==0:sum+=Int64(x)
    return sum
