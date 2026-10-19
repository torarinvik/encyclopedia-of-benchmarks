from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("knapsack_zero_one_tabulation")
fn knapsack_zero_one_tabulation(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258 or a[0]<0 or a[0]>512 or a[1]<0 or a[1]>128 or n!=c_size_t(2+2*a[1]):return -1
    let cap=Int(a[0]);let items=Int(a[1]);var dp=InlineArray[Int64,513]()
    for i in range(items):
        let w=a[2+2*i];let v=a[3+2*i]
        if w<1 or w>4096 or v<0 or v>1000000000:return -1
        for step in range(cap+1):
            let c=cap-step
            if w<=c and dp[c-Int(w)]+v>dp[c]:dp[c]=dp[c-Int(w)]+v
    return dp[cap]
