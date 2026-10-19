@export("problem35")
fn problem35(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var prime=InlineArray[Bool,500001](fill=True);prime[0]=False
    for candidate in range(3,1000001,2):
        if Int64(candidate)>1000000//Int64(candidate):break
        if prime[candidate//2]:
            var composite=candidate*candidate
            while composite<=1000000:prime[composite//2]=False;composite+=2*candidate
    var count=Int64(1)
    for number in range(3,1000001,2):
        if !prime[number//2]:continue
        var rem=number;var even=False
        while rem>0:
            if (rem%10)%2==0:even=True;break
            rem//=10
        if even:continue
        var power=1;var digits=1;rem=number
        while rem>=10:power*=10;rem//=10;digits+=1
        var rotation=number;var circular=True
        for _ in range(digits):
            if !prime[rotation//2]:circular=False;break
            rotation=(rotation%10)*power+rotation//10
        if circular:count+=1
    return count
