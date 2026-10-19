fn p14_length(start:UInt64)->UInt64:
    var current=start;var length=UInt64(1)
    while current!=1:
        if length>=10000:return 0
        if current%2==0:current//=2
        else:
            if current>6148914691236517204:return 0
            current=3*current+1
        length+=1
    return length
@export("problem14")
fn problem14(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>1000000:return -1
    var best=UInt64(1);var best_length=UInt64(1)
    for start in range(2,Int(limit+1)):
        let length=p14_length(UInt64(start))
        if length==0:return -1
        if length>best_length:best=UInt64(start);best_length=length
    return Int64(best)
