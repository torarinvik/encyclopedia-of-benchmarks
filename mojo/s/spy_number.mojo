@export("spy_number")
fn spy_number(input:Int64) abi("C")->Int64:
    if input<=0:return 0
    var value=input;var sum:Int64=0;var product:Int64=1
    while value>0:
        let digit=value%10;sum+=digit;product*=digit;value/=10
    return 1 if sum==product else 0
