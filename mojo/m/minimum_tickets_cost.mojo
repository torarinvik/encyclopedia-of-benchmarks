from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_tickets_cost")
fn minimum_tickets_cost(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>369 or v[0]<0 or v[0]>365 or Int(n)!=Int(v[0])+4:return -1
    let count=Int(v[0]);var travel=InlineArray[Int64,366](fill=0);var prev:Int64=0
    for i in range(count):
        let day=v[i+1]
        if day<1 or day>365 or day<=prev:return -1
        travel[Int(day)]=1;prev=day
    let cp=count+1
    for i in range(3):if v[cp+i]<0 or v[cp+i]>1000000:return -1
    var dp=InlineArray[Int64,397](fill=0)
    for day in range(365,0,-1):
        dp[day]=dp[day+1]
        if travel[day]!=0:
            let a=v[cp]+dp[day+1];let b=v[cp+1]+dp[day+7];let c=v[cp+2]+dp[day+30]
            dp[day]=min(a,min(b,c))
    return dp[1]
