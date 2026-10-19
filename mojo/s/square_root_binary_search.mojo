@export("square_root_binary_search")
fn square_root_binary_search(x:Int64) abi("C")->Int64:
    if x<0:return -1
    if x<2:return x
    var lo:Int64=1;var hi=x;var answer:Int64=0
    while lo<=hi:
        let mid=lo+(hi-lo)/2
        if mid<=x/mid:answer=mid;lo=mid+1
        else:hi=mid-1
    return answer
