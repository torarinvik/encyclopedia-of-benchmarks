from math import floor
@export("smith_number")
fn smith_number(x:Int64) abi("C")->Int64:
    if x<1 or x>2147395599:return -1
    var n=x;var digit:Int64=0;var q=n
    while q>0:digit+=q%10;q/=10
    var sum:Int64=0;var d:Int64=2;var composite=false
    while d*d<=n:
        while n%d==0:
            composite=true;var z=d
            while z>0:sum+=z%10;z/=10
            n/=d
        d+=1
    if n>1 and n<x:
        composite=true;var z=n
        while z>0:sum+=z%10;z/=10
    return 1 if composite and sum==digit else 0
