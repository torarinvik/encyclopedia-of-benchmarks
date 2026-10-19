@export("next_higher_number_with_same_number_of_set_bits")
fn next_higher_number_with_same_number_of_set_bits(n:Int64) abi("C")->Int64:
    if n<1 or n>1073741823:return -1
    let x=UInt64(n);let c=x&(~x+1);let r=x+c
    if c==0 or r==0:return -1
    let next=(((r^x)>>2)/c)|r
    return Int64(next)
