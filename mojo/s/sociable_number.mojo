fn sn_proper_sum(number:UInt64)->UInt64:
    if number<=1:return 0
    var total=UInt64(1);var divisor=UInt64(2)
    while divisor<=number/divisor:
        if number%divisor==0:
            let other=number/divisor;total+=divisor
            if other!=divisor:total+=other
        divisor+=1
    return total

@export("sociable_number")
fn sociable_number(number:UInt64,cycle_length:UInt64) abi("C")->Int64:
    if number==0 or number>100000 or cycle_length<2 or cycle_length>3:return -1
    var current=number
    for step in range(Int(cycle_length)):
        current=sn_proper_sum(current)
        if current==number:return 1 if UInt64(step)==cycle_length-1 else 0
    return 0
