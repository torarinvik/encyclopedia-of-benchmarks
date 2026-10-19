fn p131_prime(number:Int64)->Bool:
    if number<2:return False
    var divisor=Int64(2)
    while divisor<=number//divisor:
        if number%divisor==0:return False
        divisor+=1
    return True
@export("problem131")
fn problem131(max_prime:Int64) abi("C")->Int64:
    if max_prime<0 or max_prime>1000000:return -1
    var count=Int64(0);var cube_index=Int64(1);var candidate=Int64(7)
    while candidate<max_prime:
        if p131_prime(candidate):count+=1
        cube_index+=1;candidate+=6*cube_index
    return count
