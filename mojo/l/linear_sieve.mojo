@export("linear_sieve")
fn linear_sieve(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>4096:return -1
    if limit<2:return 0
    var least=InlineArray[Int64,4097](fill=0);var primes=InlineArray[Int64,4096](fill=0);var count=0
    for value in range(2,Int(limit)+1):
        if least[value]==0:least[value]=Int64(value);primes[count]=Int64(value);count+=1
        for i in range(count):
            let p=Int(primes[i])
            if p>least[value] or p>Int(limit)/value:break
            least[value*p]=Int64(p)
    return Int64(count)
