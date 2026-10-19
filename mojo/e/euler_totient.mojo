@export("euler_totient")
fn euler_totient(n:Int64) abi("C")->Int64:
    if n<1 or n>1000000:return -1
    var remaining=n;var result=n;var p:Int64=2
    while p*p<=remaining:
        if remaining%p==0:
            while remaining%p==0:remaining/=p
            result-=result/p
        p+=1
    if remaining>1:result-=result/remaining
    return result
