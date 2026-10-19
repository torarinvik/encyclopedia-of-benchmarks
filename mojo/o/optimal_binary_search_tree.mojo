from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("optimal_binary_search_tree")
fn optimal_binary_search_tree(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>33 or v[0]<1 or v[0]>32 or n!=c_size_t(v[0]+1):return -1
    let k=Int(v[0]);var prefix=InlineArray[Int64,33](fill=0);var dp=InlineArray[Int64,1024](fill=0)
    for i in range(k):
        let f=v[i+1]
        if f<0 or f>1000:return -1
        prefix[i+1]=prefix[i]+f;dp[i*32+i]=f
    for width in range(2,k+1):
        for start in range(k-width+1):
            let end=start+width-1;let total=prefix[end+1]-prefix[start];var best:Int64=9223372036854775807
            for root in range(start,end+1):
                let left=if root>start:dp[start*32+root-1] else:0
                let right=if root<end:dp[(root+1)*32+end] else:0
                let cost=total+left+right
                if cost<best:best=cost
            dp[start*32+end]=best
    return dp[k-1]
