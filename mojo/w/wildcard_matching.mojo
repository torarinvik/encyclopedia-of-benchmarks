from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("wildcard_matching")
fn wildcard_matching(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>35:return -1
    let tl=a[0];let pl=a[1]
    if tl<0 or tl>12 or pl<0 or pl>20 or n!=c_size_t(2+tl+pl):return -1
    for i in range(Int(tl)):if a[2+i]<97 or a[2+i]>122:return -1
    let ps=2+Int(tl)
    for i in range(Int(pl)):
        let c=a[ps+i]
        if not ((c>=97 and c<=122) or c==42 or c==63):return -1
    var dp=InlineArray[Bool,21]();dp[0]=True
    for col in range(1,Int(pl)+1):if a[ps+col-1]==42:dp[col]=dp[col-1]
    for row in range(1,Int(tl)+1):
        var next=InlineArray[Bool,21]()
        for col in range(1,Int(pl)+1):
            let token=a[ps+col-1]
            if token==a[1+row] or token==63:next[col]=dp[col-1]
            elif token==42:next[col]=dp[col] or next[col-1]
        dp=next
    return 1 if dp[Int(pl)] else 0
