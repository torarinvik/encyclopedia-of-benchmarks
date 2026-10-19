fn p113_choose(n:Int64,r:Int64)->Int64:
    var v=Int64(1)
    for i in range(1,Int(r+1)):v=v*(n+1-Int64(i))/Int64(i)
    return v
@export("problem113")
fn problem113(num_digits:Int64) abi("C")->Int64:
    if num_digits>100:return -1
    var total=Int64(0)
    for digits in range(1,Int(num_digits+1)):
        let d=Int64(digits)
        total+=p113_choose(8+d,d)+p113_choose(9+d,d)-10
    return total
