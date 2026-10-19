@export("prime_check")
fn prime_check(n:Int64) abi("C")->Int64:
    if n<2:return 0
    if n>2147483647:return -1
    if n%2==0:return 1 if n==2 else 0
    var d=Int64(3)
    while d<=n//d:
        if n%d==0:return 0
        d+=2
    return 1
