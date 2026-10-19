fn p44sc_pentagonal(x:Int64)->Bool:
    if x<0:return False
    let v=24*x+1;var low=Int64(0);var high=Int64(10000001)
    while low<=high:
        let r=low+(high-low)//2;let sq=r*r
        if sq==v:return (r+1)%6==0
        if sq<v:low=r+1
        else:high=r-1
    return False
@export("problem44_start_cursor")
fn problem44_start_cursor(k:Int64) abi("C")->Int64:
    if k<1 or k>2166:return -1
    for high in range(Int(k+1),2168):
        let ph=Int64(high*(3*high-1)//2)
        for low in range(high-1,0,-1):
            let pl=Int64(low*(3*low-1)//2);let diff=ph-pl
            if p44sc_pentagonal(diff) and p44sc_pentagonal(ph+pl):return diff
    return -1
