@export("problem124")
fn problem124(n_max:Int64,k:Int64) abi("C")->Int64:
    if n_max<1 or n_max>100000 or k<1 or k>n_max:return -1
    let n=Int(n_max);var radicals=InlineArray[Int32,100001](fill=1);var counts=InlineArray[Int32,100001](fill=0)
    for p in range(2,n+1):
        if radicals[p]==1:
            for multiple in range(p,n+1,p):radicals[multiple]*=Int32(p)
    for i in range(1,n+1):counts[Int(radicals[i])]+=1
    var remaining=Int32(k)
    for rad in range(1,n+1):
        if remaining>counts[rad]:remaining-=counts[rad];continue
        for value in range(1,n+1):
            if radicals[value]==rad:
                remaining-=1
                if remaining==0:return Int64(value)
    return -1
