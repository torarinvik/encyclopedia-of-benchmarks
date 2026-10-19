@export("problem234")
fn problem234(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>999966663333:return -1
    var root=Int64(0)
    while root+1<=limit//(root+1):root+=1
    let sieve_end=Int(root+100);var composite=InlineArray[Bool,1000100](fill=False);var primes=InlineArray[Int64,80000](fill=0);var pc=0
    for p in range(2,sieve_end):
        if composite[p]:continue
        primes[pc]=Int64(p);pc+=1
        if Int64(p)*Int64(p)<Int64(sieve_end):
            var m=p*p
            while m<sieve_end:composite[m]=True;m+=p
    var total=Int64(0);var idx=0;var p=primes[0]
    while p*p<=limit:
        let q=primes[idx+1];let lower=p*p;var upper=q*q;var current=lower+p
        while upper>current and current<=limit:total+=current;current+=p
        while upper-q>limit:upper-=q
        current=upper-q
        while current>lower:total+=current;current-=q
        current=0
        while upper>current and current<=limit:
            if current<=lower:current+=p*q;continue
            if current>limit:break
            total-=2*current;current+=p*q
        p=q;idx+=1
    return total
