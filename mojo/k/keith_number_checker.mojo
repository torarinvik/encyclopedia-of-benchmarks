@export("keith_number_checker")
fn keith_number_checker(x:Int64) abi("C")->Int64:
    if x<2 or x>1000:return -1
    var d=0;var v=x
    while v>0:d+=1;v//=10
    var seq=InlineArray[Int64,1024]();v=x
    for i in range(d):seq[d-1-i]=v%10;v//=10
    var k=d;var s:Int64=0
    while s<x:
        s=0
        for j in range(1,d+1):s+=seq[k-j]
        seq[k]=s;k+=1
    return 1 if s==x else 0
