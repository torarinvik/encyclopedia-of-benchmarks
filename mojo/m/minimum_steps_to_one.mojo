@export("minimum_steps_to_one")
fn minimum_steps_to_one(n:Int64) abi("C")->Int64:
    if n<1 or n>10000:return -1
    var dp=InlineArray[Int64,10001](fill=0)
    for i in range(10001):dp[i]=n+1
    dp[1]=0
    for i in range(1,Int(n)):
        if dp[i+1]>dp[i]+1:dp[i+1]=dp[i]+1
        if i*2<=Int(n) and dp[i*2]>dp[i]+1:dp[i*2]=dp[i]+1
        if i*3<=Int(n) and dp[i*3]>dp[i]+1:dp[i*3]=dp[i]+1
    return dp[Int(n)]
