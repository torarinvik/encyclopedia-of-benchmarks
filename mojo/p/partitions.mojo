comptime STRIDE=101
fn parts_count(n:Int,k:Int,mut memo:InlineArray[Int64,10201])->Int64:
    if (n==0 and k==0) or (n>0 and k==1) or n==k:return 1
    if k==0 or k>n:return 0
    let ix=n*STRIDE+k
    if memo[ix]>=0:return memo[ix]
    memo[ix]=parts_count(n-1,k-1,mut memo)+parts_count(n-k,k,mut memo)
    return memo[ix]
@export("partitions")
fn partitions(n:Int64) abi("C")->Int64:
    if n<0 or n>100:return -9223372036854775808
    var memo=InlineArray[Int64,10201](fill=-1);var total:Int64=0
    for k in range(1,Int(n)+1):total+=parts_count(Int(n),k,mut memo)
    return 1 if n==0 else total
