@export("problem135")
fn problem135(limit:Int64) abi("C")->Int64:
    if limit>1000000:return -1
    if limit<0:return 0
    var frequency=InlineArray[UInt8,1000001](fill=0)
    for first in range(1,Int(limit+1)):
        var n=first
        while n<=limit:
            var d=Int64(first)+n//Int64(first)
            if d%4==0:
                d//=4
                if Int64(first)>d and Int64(first)<4*d and frequency[n]<11:frequency[n]+=1
            n+=first
    var count=Int64(0)
    for n in range(1,Int(limit+1)):if frequency[n]==10:count+=1
    return count
