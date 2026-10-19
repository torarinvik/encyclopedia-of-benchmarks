@export("problem100")
fn problem100(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>1000000000000:return -1
    var pn=Int64(1);var pd=Int64(0);var n=Int64(1);var d=Int64(1)
    while n<=2*limit-1:
        pn+=2*n;n+=2*pn;pd+=2*d;d+=2*pd
    return (d+1)//2
