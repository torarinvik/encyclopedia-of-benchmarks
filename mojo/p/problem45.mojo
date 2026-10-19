@export("problem45")
fn problem45(start:Int64) abi("C")->Int64:
    if start<0 or start>27693:return -1
    for n in range(Int(start),30000):
        let value=Int64(n)*Int64(2*n-1);let test=24*value+1;var low=Int64(0);var high=Int64(6000001);var root=Int64(-1)
        while low<=high:
            let mid=low+(high-low)//2;let sq=mid*mid
            if sq==test:root=mid;break
            if sq<test:low=mid+1
            else:high=mid-1
        if root>=0 and (root+1)%6==0:return value
    return -1
