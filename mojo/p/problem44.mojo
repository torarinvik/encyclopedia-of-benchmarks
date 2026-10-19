fn p44_pentagonal(x:Int64)->Bool:
    if x<0:return False
    let v=24*x+1;var low=Int64(0);var high=Int64(10000001)
    while low<=high:
        let r=low+(high-low)//2;let sq=r*r
        if sq==v:return (r+1)%6==0
        if sq<v:low=r+1
        else:high=r-1
    return False
@export("problem44")
fn problem44(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>5000:return -1
    for lower in range(1,Int(limit)):
        let pl=Int64(lower*(3*lower-1)//2)
        for upper in range(lower,Int(limit)):
            let pu=Int64(upper*(3*upper-1)//2);let diff=pu-pl
            if diff>0 and p44_pentagonal(diff) and p44_pentagonal(pu+pl):return diff
    return -1
