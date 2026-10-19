@export("modular_inverse")
fn modular_inverse(a:Int64,m:Int64) abi("C")->Int64:
    if a<0 or a>1000000 or m<2 or m>1000000:return -1
    var oldr=a%m;var r=m;var olds:Int64=1;var s:Int64=0
    while r!=0:
        let q=oldr/r;let nr=oldr-q*r;let ns=olds-q*s
        oldr=r;r=nr;olds=s;s=ns
    if oldr!=1:return -1
    let x=olds%m
    return x+m if x<0 else x
