@export("nthprime")
fn nthprime(n:Int64) abi("C")->Int64:
    if n<1 or n>100:return -1
    var size=Int(n)*2
    while True:
        var sieve=InlineArray[Bool,1600](fill=True)
        sieve[0]=False;sieve[1]=False
        var p=2
        while p*p<size:
            if sieve[p]:
                var j=p*p
                while j<size:sieve[j]=False;j+=p
            p+=1
        var count=0
        for i in range(2,size):if sieve[i]:count+=1
        if count>=Int(n):
            count=0
            for i in range(2,size):
                if sieve[i]:
                    count+=1
                    if count==Int(n):return i
        size+=Int(n)
