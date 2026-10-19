fn p21_divisors(value:Int64)->Int64:
    if value<=1:return 0
    var total=Int64(1);var d=Int64(2)
    while d<=value//d:
        if value%d==0:
            total+=d
            let pair=value//d
            if pair!=d:total+=pair
        d+=1
    return total
@export("problem21")
fn problem21(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>10000:return -1
    var total=Int64(0)
    for a in range(1,Int(limit)):
        let b=p21_divisors(Int64(a))
        if b!=a and p21_divisors(b)==Int64(a):total+=Int64(a)
    return total
