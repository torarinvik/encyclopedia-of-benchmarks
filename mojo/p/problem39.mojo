fn p39_sqrt(value:Int64)->Int64:
    var low=Int64(0);var high=Int64(1415)
    while high-low>1:
        let mid=(low+high)//2
        if mid*mid<=value:low=mid
        else:high=mid
    return low
@export("problem39")
fn problem39(limit:Int64) abi("C")->Int64:
    if limit<12 or limit>1000:return -1
    var counts=InlineArray[Int32,1001](fill=0);var first=InlineArray[Int32,1001](fill=0);var order=1
    for a in range(1,Int(limit+1)):
        for b in range(a,Int(limit+1)):
            let ss=Int64(a*a+b*b);let h=p39_sqrt(ss)
            if h*h!=ss:continue
            let perimeter=Int64(a+b)+h
            if perimeter>limit:continue
            if counts[Int(perimeter)]==0:first[Int(perimeter)]=Int32(order);order+=1
            counts[Int(perimeter)]+=1
    var bestp=Int64(-1);var bestc=Int32(0);var besto=2147483647
    for p in range(1,Int(limit+1)):
        if counts[p]>0 and (counts[p]>bestc or (counts[p]==bestc and first[p]<besto)):
            bestp=Int64(p);bestc=counts[p];besto=first[p]
    return bestp
