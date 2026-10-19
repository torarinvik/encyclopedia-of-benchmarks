@export("problem50")
fn problem50(limit:Int64) abi("C")->Int64:
    if limit<3 or limit>1000000:return -1
    var composite=InlineArray[Bool,1000000](fill=False)
    for p in range(2,1001):
        if !composite[p]:
            var m=p*p
            while m<1000000:composite[m]=True;m+=p
    var primes=InlineArray[Int32,80000](fill=0);var pc=0
    for i in range(2,Int(limit)):
        if !composite[i]:primes[pc]=Int32(i);pc+=1
    var best=Int64(0);var bestlen=0
    for start in range(pc):
        var sum=Int64(0)
        for end in range(start,pc):
            sum+=Int64(primes[end])
            if sum>=limit:break
            let length=end-start+1
            if length>=bestlen and !composite[Int(sum)]:best=sum;bestlen=length
    return best
