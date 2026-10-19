fn p87_sqrt(value:Int64)->Int64:
    var low=Int64(0);var high=Int64(7072)
    while low<=high:
        let mid=low+(high-low)//2
        if mid*mid<=value:low=mid+1
        else:high=mid-1
    return high
@export("problem87")
fn problem87(limit:Int64) abi("C")->Int64:
    if limit<24 or limit>50000000:return -1
    let bound=p87_sqrt(limit-24);var prime=InlineArray[Bool,7072](fill=False)
    for p in range(2,Int(bound+1)):prime[p]=True
    for p in range(2,Int(bound+1)):
        if prime[p]:
            var multiple=p*p
            while multiple<=bound:prime[multiple]=False;multiple+=p
    var seen=InlineArray[UInt64,781250](fill=0)
    for p1 in range(2,Int(bound+1)):
        if !prime[p1]:continue
        let square=Int64(p1)*Int64(p1)
        for p2 in range(2,Int(bound+1)):
            if !prime[p2]:continue
            let cube=Int64(p2)*Int64(p2)*Int64(p2)
            if square+cube>=limit-16:break
            for p3 in range(2,Int(bound+1)):
                if !prime[p3]:continue
                let value=square+cube+Int64(p3)*Int64(p3)*Int64(p3)*Int64(p3)
                if value>=limit:break
                let index=Int(value);seen[index//64]|=UInt64(1)<<(index%64)
    var count=Int64(0)
    for i in range(Int((limit+63)//64)):
        var bits=seen[i]
        while bits!=0:count+=1;bits&=bits-1
    return count
