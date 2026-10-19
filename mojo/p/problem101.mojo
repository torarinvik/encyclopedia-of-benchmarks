fn p101_u(n:Int64)->Int64:
    var term=Int64(1);var total=Int64(0)
    for e in range(11):
        if e%2==0:total+=term
        else:total-=term
        term*=n
    return total
@export("problem101")
fn problem101(order:Int64) abi("C")->Int64:
    if order>10:return -1
    if order<=0:return 0
    var data=InlineArray[Int64,10](fill=0)
    for i in range(Int(order)):data[i]=p101_u(Int64(i+1))
    var total=Int64(0)
    for k in range(1,Int(order)+1):
        var row=InlineArray[Int64,10](fill=0);var dif=InlineArray[Int64,10](fill=0)
        for i in range(k):row[i]=data[i]
        dif[0]=row[0]
        for lev in range(1,k):
            for i in range(k-lev):row[i]=row[i+1]-row[i]
            dif[lev]=row[0]
        var x=Int64(1);var pred=Int64(0)
        while True:
            pred=0;var choose=Int64(1)
            for j in range(k):
                pred+=dif[j]*choose
                if j+1<k:choose=choose*(x-1-Int64(j))/Int64(j+1)
            if pred==p101_u(x):x+=1
            else:break
        total+=pred
    return total
