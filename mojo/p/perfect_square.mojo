@export("perfect_square")
fn perfect_square(x:Int64) abi("C")->Int64:
    if x<0:return 0
    if x<2:return 1
    let num=UInt64(x);var lo:UInt64=1;var hi=num/2
    while lo<=hi:
        let mid=lo+(hi-lo)/2;let q=num/mid
        if q==mid:
            if num%mid==0:return 1
            lo=mid+1
        elif q<mid:hi=mid-1
        else:lo=mid+1
    return 0
