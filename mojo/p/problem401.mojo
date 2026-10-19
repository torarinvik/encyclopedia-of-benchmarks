@export("problem401")
fn problem401(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>1000:return -1
    var total=Int64(0)
    for n in range(2,Int(limit+1)):
        for d in range(2,n+1):
            if n%d==0:total=(total+Int64(d)*Int64(d))%1000000000
    return total
