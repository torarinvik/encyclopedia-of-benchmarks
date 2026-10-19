@export("weird_number")
fn weird_number(n:Int64) abi("C")->Int64:
    if n<0 or n>512:return -1
    if n==0:return 0
    var divs=InlineArray[Int64,512]();var count=0;var sum:Int64=0
    for d in range(1,Int(n)):
        if n%Int64(d)==0:divs[count]=Int64(d);count+=1;sum+=Int64(d)
    if sum<=n:return 0
    var reachable=InlineArray[Bool,513]();reachable[0]=True
    for i in range(count):
        let d=Int(divs[i])
        for s in range(Int(n),d-1,-1):if reachable[s-d]:reachable[s]=True
    return 0 if reachable[Int(n)] else 1
