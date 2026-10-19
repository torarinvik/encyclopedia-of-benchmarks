@export("problem6")
fn problem6(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>100:return -1
    var sum=Int64(0);var squares=Int64(0)
    for i in range(1,Int(limit+1)):sum+=Int64(i);squares+=Int64(i*i)
    return sum*sum-squares
