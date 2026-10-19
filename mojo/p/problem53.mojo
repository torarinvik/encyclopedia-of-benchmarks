@export("problem53")
fn problem53(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var count=Int64(0)
    for n in range(1,101):
        var c=Int64(1)
        for r in range(1,n+1):
            c=c*Int64(n-r+1)//Int64(r)
            if c>1000000:count+=Int64(n-2*r+1);break
    return count
