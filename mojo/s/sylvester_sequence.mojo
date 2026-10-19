fn sylvester_term(n:Int64)->Int64:
    if n==1:return 2
    let previous=sylvester_term(n-1)
    return previous*(previous-1)+1
@export("sylvester_sequence")
fn sylvester_sequence(n:Int64) abi("C")->Int64:
    if n<1 or n>7:return -1
    return sylvester_term(n)
