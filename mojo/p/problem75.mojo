fn p75_gcd(a_in:Int64,b_in:Int64)->Int64:
    var a=a_in;var b=b_in
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("problem75")
fn problem75(limit:Int64) abi("C")->Int64:
    if limit>1500000:return -1
    if limit<0:return 0
    var frequency=InlineArray[UInt8,1500001](fill=0)
    for m in range(2,1501):
        if 2*m*(m+1)>limit:break
        var n=(m%2)+1
        while n<m:
            if p75_gcd(Int64(m),Int64(n))==1:
                let primitive=2*m*(m+n);var perimeter=primitive
                while perimeter<=limit:
                    if frequency[perimeter]<2:frequency[perimeter]+=1
                    perimeter+=primitive
            n+=2
    var unique=Int64(0)
    for p in range(1,Int(limit+1)):if frequency[p]==1:unique+=1
    return unique
