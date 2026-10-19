@export("deficient_numbers")
fn deficient_numbers(number:Int64) abi("C")->Int64:
    if number<=0:return 0
    if number>100000000:return -1
    if number==1:return 1
    var total:Int64=1;var d:Int64=2
    while d<=number/d:
        if number%d==0:
            let other=number/d;total+=d
            if other!=d:total+=other
        d+=1
    return 1 if total<number else 0
