@export("problem72")
fn problem72(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>1000000:return -1
    if limit<2:return 0
    var phi=InlineArray[Int32,1000001](fill=0);phi[1]=1
    for v in range(2,Int(limit+1)):phi[v]=Int32(v)
    for p in range(2,Int(limit+1)):
        if phi[p]==Int32(p):
            var m=p
            while m<=limit:phi[m]-=phi[m]//Int32(p);m+=p
    var total=Int64(0)
    for d in range(2,Int(limit+1)):total+=Int64(phi[d])
    return total
