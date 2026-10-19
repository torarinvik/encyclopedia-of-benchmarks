@export("next_prime_number")
fn next_prime_number(n:Int64) abi("C")->Int64:
    if n< -4096 or n>4096:return -1
    var candidate=max(Int64(2),n+1)
    while candidate<=4099:
        var prime=true
        var d:Int64=2
        while d*d<=candidate:
            if candidate%d==0:prime=false;break
            d+=1
        if prime:return candidate
        candidate+=1
    return -1
