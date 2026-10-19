fn p49_prime(n:Int)->Bool:
    if n<2:return False
    if n%2==0:return n==2
    var d=3
    while d<=n//d:
        if n%d==0:return False
        d+=2
    return True
fn p49_key(value_in:Int)->Int:
    var value=value_in;var counts=InlineArray[Int32,10](fill=0)
    while value>0:counts[value%10]+=1;value//=10
    var key=0
    for d in range(10):
        for _ in range(Int(counts[d])):key=key*10+d
    return key
@export("problem49")
fn problem49(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var primes=InlineArray[Int32,1250](fill=0);var keys=InlineArray[Int32,1250](fill=0);var count=0
    for n in range(1001,10000,2):
        if p49_prime(n):primes[count]=Int32(n);keys[count]=Int32(p49_key(n));count+=1
    var best=Int64(0)
    for i in range(count):
        var first_for_key=True
        for q in range(i):if keys[q]==keys[i]:first_for_key=False;break
        if !first_for_key:continue
        var family=InlineArray[Int32,1250](fill=0);var fc=0
        for q in range(i,count):if keys[q]==keys[i]:family[fc]=primes[q];fc+=1
        var family_best=Int64(0)
        for a in range(fc):
            for b in range(a+1,fc):
                let third=2*family[b]-family[a]
                for c in range(b+1,fc):
                    if family[c]==third:
                        let concat=Int64(family[a])*100000000+Int64(family[b])*10000+Int64(family[c])
                        if family_best==0:family_best=concat
                        break
                if family_best!=0:break
            if family_best!=0:break
        if family_best>best:best=family_best
    return best
