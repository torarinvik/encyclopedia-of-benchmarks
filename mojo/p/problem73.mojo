fn p73_gcd(a_in:Int64,b_in:Int64)->Int64:
    var a=a_in;var b=b_in
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("problem73")
fn problem73(max_denominator:Int64) abi("C")->Int64:
    if max_denominator<0 or max_denominator>12000:return -1
    var count=Int64(0)
    for d in range(Int(max_denominator+1)):
        var start=d//3+1;var step=1
        if d%2==0:start+=1-start%2;step=2
        let end=(d+1)//2
        for n in range(start,end,step):
            if p73_gcd(Int64(n),Int64(d))==1:count+=1
    return count
