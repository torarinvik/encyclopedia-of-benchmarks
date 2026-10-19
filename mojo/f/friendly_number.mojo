fn fn_sum_divisors(n:UInt64)->Int64:
    var total:Int64=0;var d:UInt64=1
    while d*d<=n:
        if n%d==0:
            total+=Int64(d)
            let other=n/d
            if other!=d:total+=Int64(other)
        d+=1
    return total

@export("friendly_number")
fn friendly_number(a:UInt64,b:UInt64) abi("C")->Int64:
    if a>1000000 or b>1000000:return -1
    if a==0 or b==0:return 0
    return 1 if fn_sum_divisors(a)*Int64(b)==fn_sum_divisors(b)*Int64(a) else 0
