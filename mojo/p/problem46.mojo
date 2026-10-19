fn p46_prime(value:Int64)->Bool:
    if value<2:return False
    var d=Int64(2)
    while d<=value//d:
        if value%d==0:return False
        d+=1
    return True
@export("problem46")
fn problem46(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    for n in range(3,100000,2):
        if p46_prime(Int64(n)):continue
        var represented=False;var i=Int64(0)
        while 2*i*i<=n:
            if p46_prime(Int64(n)-2*i*i):represented=True;break
            i+=1
        if !represented:return Int64(n)
    return -1
