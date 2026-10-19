@export("minimum_squares_to_represent_a_number")
fn minimum_squares_to_represent_a_number(n:Int64) abi("C")->Int64:
    if n<0 or n>4096:return -1
    if n==0:return 1
    var dp=InlineArray[Int64,4097](fill=0)
    for i in range(1,Int(n)+1):
        var best=9223372036854775807;var r=1
        while r<=i//r:
            let x=1+dp[i-r*r]
            if x<best:best=x
            r+=1
        dp[i]=best
    return dp[Int(n)]
