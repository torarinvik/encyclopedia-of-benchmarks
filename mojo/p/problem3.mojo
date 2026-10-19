@export("problem3")
fn problem3(number_in:Int64) abi("C")->Int64:
    if number_in<2 or number_in>600851475143:return -1
    var number=number_in;var factor=Int64(2);var largest=Int64(1)
    while factor<=number//factor:
        if number%factor==0:
            largest=factor
            while number%factor==0:number//=factor
        factor+=1 if factor==2 else 2
    if number>1:largest=number
    return largest
