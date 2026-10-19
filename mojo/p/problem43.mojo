fn p43_next(inout d:InlineArray[Int32,10])->Bool:
    var pivot=8
    while pivot>=0 and d[pivot]>=d[pivot+1]:pivot-=1
    if pivot<0:return False
    var succ=9
    while d[succ]<=d[pivot]:succ-=1
    let t=d[pivot];d[pivot]=d[succ];d[succ]=t
    var l=pivot+1;var r=9
    while l<r:let x=d[l];d[l]=d[r];d[r]=x;l+=1;r-=1
    return True
@export("problem43")
fn problem43(n:Int64) abi("C")->Int64:
    if n!=10:return -1
    var d=InlineArray[Int32,10](fill=0)
    for i in range(10):d[i]=Int32(i)
    var total=Int64(0)
    while True:
        var good=True
        for i in range(1,8):
            let val=d[i]*100+d[i+1]*10+d[i+2]
            var divisor=2
            if i==2:divisor=3
            elif i==3:divisor=5
            elif i==4:divisor=7
            elif i==5:divisor=11
            elif i==6:divisor=13
            elif i==7:divisor=17
            if val%divisor!=0:good=False;break
        if good:
            var value=Int64(0)
            for j in range(10):value=value*10+Int64(d[j])
            total+=value
        if !p43_next(d):break
    return total
