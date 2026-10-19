@export("kynea_numbers")
fn kynea_numbers(n:Int64) abi("C")->Int64:
    if n<1 or n>31:return -1
    let p=(Int64(1)<<Int(n))+1
    return p*p-2
