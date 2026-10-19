@export("greatest_prime_factor")
fn greatest_prime_factor(n:Int64) abi("C")->Int64:
    if n<0 or n>1000000:return -1
    if n<2:return n
    var quotient=n;var largest:Int64=0;var factor:Int64=2
    while quotient!=1:
        var prime=True
        if factor<2:prime=False
        else:
            var d:Int64=2
            while d<=factor//d:
                if factor%d==0:prime=False;break
                d+=1
        if prime and quotient%factor==0:largest=factor;quotient//=factor
        else:factor+=1
    return largest
