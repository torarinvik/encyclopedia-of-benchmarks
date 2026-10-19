@export("trimorphic_number")
fn trimorphic_number(n:Int64) abi("C")->Int64:
    if n<0 or n>2000000:return -1
    var digits:Int64=1;var t=n
    while t>=10:t/=10;digits+=1
    var modulus:Int64=1
    for _ in range(Int(digits)):modulus*=10
    let cube=n*n*n
    return 1 if cube%modulus==n else 0
