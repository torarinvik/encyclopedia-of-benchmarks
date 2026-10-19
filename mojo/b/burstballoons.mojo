from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("burstballoons")
fn burstballoons(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>128 or (length>0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let n=Int(length)
    for i in range(n):
        if values[i]<0 or values[i]>1000:return -1
    if n==0:return 0
    var padded=List[Int64](length=n+2,fill=1)
    var dp=List[Int64](length=(n+2)*(n+2),fill=0)
    for i in range(n):padded[i+1]=values[i]
    for span in range(1,n+1):
        for left in range(1,n-span+2):
            let right=left+span-1;var best:Int64=0
            for last in range(left,right+1):
                let score=dp[left*(n+2)+last-1]+dp[(last+1)*(n+2)+right]+padded[left-1]*padded[last]*padded[right+1]
                if score>best:best=score
            dp[left*(n+2)+right]=best
    return dp[(n+2)+n]
