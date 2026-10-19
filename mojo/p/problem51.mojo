fn p51_prime(n:Int)->Bool:
    if n<2:return False
    if n%2==0:return n==2
    var d=3
    while d<=n//d:
        if n%d==0:return False
        d+=2
    return True
fn p51_distinct(n:Int)->Int:
    var seen=InlineArray[Bool,10](fill=False);var x=n;var count=0
    while x>0:
        let d=x%10
        if !seen[d]:seen[d]=True;count+=1
        x//=10
    return count
@export("problem51")
fn problem51(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    for prime in range(2,1000000):
        if !p51_prime(prime):continue
        var digits=prime;var len=0;while digits>0:len+=1;digits//=10
        if len-p51_distinct(prime)<3:continue
        var patterns=InlineArray[Int32,10](fill=0);var pc=0;digits=prime
        var dcounts=InlineArray[Int32,10](fill=0)
        while digits>0:dcounts[digits%10]+=1;digits//=10
        for d in range(10):if dcounts[d]>=2:patterns[pc]=Int32(d);pc+=1
        for pi in range(pc):
            let target=patterns[pi];var family=0;var smallest=Int64(0)
            for replacement in range(10):
                var value=0;var place=1;var x=prime;var valid=True
                while x>0:
                    let digit=x%10
                    let outdigit=replacement if digit==Int(target) else digit
                    if outdigit==0 and x<10:valid=False
                    value+=outdigit*place;place*=10;x//=10
                if valid and p51_prime(value) and len-p51_distinct(value)>=3:
                    family+=1
                    if smallest==0 or Int64(value)<smallest:smallest=Int64(value)
            if family==8:return smallest
    return -1
