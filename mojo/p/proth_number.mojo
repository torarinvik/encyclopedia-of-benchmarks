@export("is_proth_number")
fn is_proth_number(input:Int64) abi("C")->Int64:
    if input<=0:return -1
    if input==1:return 0
    var remainder=input-1;var exponent=0
    while remainder%2==0:exponent+=1;remainder//=2
    return 1 if remainder<(Int64(1)<<exponent) else 0
