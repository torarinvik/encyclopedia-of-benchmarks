@export("trial_division_factorizer")
fn trial_division_factorizer(n:Int64) abi("C")->Int64:
    if n< -2147483647 or n>2147483647 or n==0:return -1
    let x=if n<0 then -n else n
    var d:Int64=2
    while d<=x/d:
        if x%d==0:return d
        d+=1
    return 0
