@export("problem21_pair_sum")
fn problem21_pair_sum(n:Int64) abi("C")->Int64:
    if n<2 or n>10000:return -1
    var total=Int64(0)
    for a in range(2,Int(n)):
        let b=p21_divisors(Int64(a))
        if b>Int64(a) and p21_divisors(b)==Int64(a):total+=Int64(a)+b
    return total
