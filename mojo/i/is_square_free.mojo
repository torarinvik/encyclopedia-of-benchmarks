@export("is_square_free")
fn is_square_free(n:Int64) abi("C")->Int64:
    if n<1 or n>1000000:return -1
    var value=n;var factor:Int64=2
    while factor<=value//factor:
        if value%factor==0:
            value//=factor
            if value%factor==0:return 0
        factor+=1
    return 1
