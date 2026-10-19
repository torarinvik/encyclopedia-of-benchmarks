fn tp_prime(n:Int64)->Bool:
    if n<2:return False
    var d:Int64=2
    while d*d<=n:
        if n%d==0:return False
        d+=1
    return True
@export("twin_prime")
fn twin_prime(n:Int64) abi("C")->Int64:
    if n< -4096 or n>4096:return -1
    return n+2 if tp_prime(n) and tp_prime(n+2) else -1
