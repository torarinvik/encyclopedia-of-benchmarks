from std.math import max

fn phi(value:UInt64)->UInt64:
    var result=value;var remaining=value;var factor=UInt64(2)
    while factor<=remaining/factor:
        if remaining%factor==0:
            result-=result/factor
            while remaining%factor==0:remaining/=factor
        factor+=if factor==2:1 else:2
    if remaining>1:result-=result/remaining
    return result
@export("lcm_sum")
fn lcm_sum(n:Int64) abi("C")->Int64:
    if n<1 or n>65535:return -1
    let u=UInt64(n);var sum=UInt64(1);var d=UInt64(1)
    while d<=u/d:
        if u%d==0:
            sum+=d*phi(d);let p=u/d
            if p!=d:sum+=p*phi(p)
        d+=1
    return Int64((sum*u)/2)
