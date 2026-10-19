from std.math import min
@export("problem10")
fn problem10(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>2000000:return -1
    var composite=InlineArray[Bool,1000000](fill=False);let odd=Int(limit//2);var sum=Int64(2 if limit>2 else 0)
    var p=3
    while p*p<limit:
        if not composite[p//2]:
            var j=p*p//2
            while j<odd:composite[j]=True;j+=p
        p+=2
    for i in range(1,odd):if not composite[i]:sum+=Int64(2*i+1)
    return sum
