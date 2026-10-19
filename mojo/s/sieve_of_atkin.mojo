@export("sieve_of_atkin")
fn sieve_of_atkin(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>4096:return -1
    if limit<2:return 0
    let n=Int(limit);var sieve=InlineArray[Bool,4097]()
    var x=1;while x<=n/x:
        var y=1;while y<=n/y:
            let a=4*x*x+y*y;if a<=n and (a%12==1 or a%12==5):sieve[a]=not sieve[a]
            let b=3*x*x+y*y;if b<=n and b%12==7:sieve[b]=not sieve[b]
            if x>y:let c=3*x*x-y*y;if c<=n and c%12==11:sieve[c]=not sieve[c]
            y+=1
        x+=1
    var p=5;while p<=n/p:if sieve[p]:var m=p*p;while m<=n:sieve[m]=False;m+=p;p+=1
    var count=1;if n>=3:count+=1
    for i in range(5,n+1):if sieve[i]:count+=1
    return count
