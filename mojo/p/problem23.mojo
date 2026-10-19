@export("problem23")
fn problem23(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>28123:return -1
    var sums=InlineArray[Int32,28124](fill=0);var abundant=InlineArray[Int,28124](fill=0);var ac=0
    for d in range(1,Int(limit//2+1)):
        var n=d*2
        while n<=limit:sums[n]+=Int32(d);n+=d
    for n in range(1,Int(limit+1)):
        if sums[n]>n:abundant[ac]=n;ac+=1
    var can=InlineArray[Bool,28124](fill=False)
    for i in range(ac):
        for j in range(i,ac):
            let s=abundant[i]+abundant[j]
            if s>Int(limit):break
            can[s]=True
    var total=Int64(0)
    for n in range(1,Int(limit+1)):if !can[n]:total+=Int64(n)
    return total
