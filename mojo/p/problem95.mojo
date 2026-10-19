@export("problem95")
fn problem95(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>1000000:return -1
    var sums=InlineArray[UInt32,1000001](fill=0)
    for divisor in range(1,Int(limit//2+1)):
        var multiple=2*divisor
        while multiple<=limit:sums[multiple]+=UInt32(divisor);multiple+=divisor
    let mark=UInt32(0x80000000);let mask=UInt32(0x7fffffff);var best=0;var answer=Int64(0)
    for start in range(2,Int(limit+1)):
        var current=sums[start];var length=1;sums[start]|=mark
        while current>1 and current<=limit and (sums[Int(current)]&mark)==0:
            sums[Int(current)]|=mark;current=sums[Int(current)]&mask;length+=1
        if current==UInt32(start) and length>best:best=length;answer=Int64(start)
        current=UInt32(start)
        for _ in range(length):
            let next=sums[Int(current)]&mask;sums[Int(current)]=next;current=next
    return answer
