@export("prime_pi_sequence")
fn prime_pi_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>999:return -1
    let target=Int(index+1);var primes=InlineArray[Int64,168](fill=0);var count=0
    if target>=2:primes[count]=2;count+=1
    for c in range(3,target+1,2):
        var prime=True
        for i in range(count):if c%Int(primes[i])==0:prime=False;break
        if prime:primes[count]=Int64(c);count+=1
    return Int64(count)
