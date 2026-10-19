fn p14_length(start:UInt64)->UInt64:
    var x=start;var len=UInt64(1)
    while x!=1:
        if len>=10000:return 0
        if x%2==0:x//=2
        else:
            if x>3002399751580330:return 0
            x=3*x+1
        len+=1
    return len
@export("problem014")
fn problem014(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>1000000:return -1
    var best=UInt64(1);var bestlen=UInt64(1)
    for s in range(2,Int(limit)):
        let len=p14_length(UInt64(s))
        if len==0:return -1
        if len>bestlen:best=UInt64(s);bestlen=len
    return Int64(best)
