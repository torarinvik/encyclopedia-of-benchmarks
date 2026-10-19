@export("primes_sequence")
fn primes_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>99:return -1
    var primes=InlineArray[Int64,100](fill=0);primes[0]=2;var count=1;var candidate=3
    while count<=Int(index):
        var prime=True
        for i in range(count):if candidate%Int(primes[i])==0:prime=False;break
        if prime:primes[count]=Int64(candidate);count+=1
        candidate+=2
    return primes[Int(index)]
