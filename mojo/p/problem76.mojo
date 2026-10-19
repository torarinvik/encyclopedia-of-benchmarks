@export("problem76")
fn problem76(total:Int64) abi("C")->Int64:
    if total<1 or total>200:return -1
    var memo=InlineArray[Int64,40200](fill=0)
    for n in range(Int(total+1)):memo[n*200]=1
    for n in range(Int(total+1)):
        for k in range(1,Int(total)):
            let index=n*200+k;memo[index]+=memo[index-1]
            if n>k:memo[index]+=memo[(n-k-1)*200+k]
    return memo[Int(total)*200+Int(total)-1]-1
