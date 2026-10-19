@export("sieve_of_eratosthenes")
fn sieve_of_eratosthenes(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>4096:return -1
    if limit<2:return 0
    var sieve=InlineArray[Bool,4097]();for i in range(2,Int(limit)+1):sieve[i]=True
    var p=2;while p<=Int(limit)/p:if sieve[p]:var m=p*p;while m<=Int(limit):sieve[m]=False;m+=p;p+=1
    var count=0;for i in range(2,Int(limit)+1):if sieve[i]:count+=1
    return count
