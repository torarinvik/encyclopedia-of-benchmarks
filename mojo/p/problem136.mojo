@export("problem136")
fn problem136(n_limit:Int64) abi("C")->Int64:
    if n_limit>100000:return -1
    if n_limit<=0:return 0
    var solutions=InlineArray[UInt8,100000](fill=0)
    let max_delta=Int((n_limit+1)//4)
    for delta in range(1,max_delta+1):
        var y=4*delta-1
        while y>delta:
            let n=y*(4*delta-y)
            if n>=n_limit:break
            if solutions[Int(n)]<2:solutions[Int(n)]+=1
            y-=1
    var answer=Int64(0)
    for n in range(Int(n_limit)):if solutions[n]==1:answer+=1
    return answer
