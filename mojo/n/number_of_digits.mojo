@export("number_of_digits")
fn number_of_digits(n:Int64) abi("C")->Int64:
    var magnitude:UInt64
    if n<0:magnitude=UInt64(-(n+1))+1
    else:magnitude=UInt64(n)
    var digits:Int64=1
    while magnitude>=10:magnitude=magnitude/10;digits+=1
    return digits
