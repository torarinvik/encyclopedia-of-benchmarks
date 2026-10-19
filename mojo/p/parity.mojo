@export("parity")
fn parity(number:Int64) abi("C")->Int64:
    if number<0:return -1
    var n=number;var answer:Int64=0
    while n!=0:answer^=1;n &= n-1
    return answer
