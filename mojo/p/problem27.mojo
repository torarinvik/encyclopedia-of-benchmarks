fn p27_prime(value:Int64)->Bool:
    if value<2:return False
    if value%2==0:return value==2
    if value%3==0:return value==3
    var factor=Int64(5)
    while factor<=value//factor:
        if value%factor==0 or value%(factor+2)==0:return False
        factor+=6
    return True
@export("problem27")
fn problem27(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>1000:return -1
    var best=Int64(0);var best_a=Int64(0);var best_b=Int64(0)
    for a in range(Int(1-limit),Int(limit)):
        for b in range(2,Int(limit)):
            if !p27_prime(Int64(b)):continue
            var n=Int64(0)
            while p27_prime(n*n+Int64(a)*n+Int64(b)):n+=1
            if n>best:best=n;best_a=Int64(a);best_b=Int64(b)
    return best_a*best_b
