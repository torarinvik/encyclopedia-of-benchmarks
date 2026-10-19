@export("max_69_number")
fn max_69_number(value:Int64) abi("C")->Int64:
    if value<1 or value>999999999999999999:return -1
    var place:Int64=1
    while place<=value/10:place*=10
    var p=place
    while p>0:
        let digit=(value/p)%10
        if digit==6:return value+3*p
        if digit!=9:return -1
        p/=10
    return -1
