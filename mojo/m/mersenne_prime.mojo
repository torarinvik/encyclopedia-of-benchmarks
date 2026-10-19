from std.memory import ImmutAnyOrigin, UnsafePointer
fn mp_prime(n:Int64)->Bool:
    if n<2:return False
    if n%2==0:return n==2
    var f:Int64=3
    while f<=n/f:
        if n%f==0:return False
        f+=2
    return True
@export("mersenne_prime")
fn mersenne_prime(n:Int64) abi("C")->Int64:
    if n==0:return 0
    if n<0 or n>2147483647:return -1
    var rest=n+1
    while rest%2==0:rest/=2
    if rest!=1:return 0
    return 1 if mp_prime(n) else 0
