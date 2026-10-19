@export("multiple_of_3_or_5_term")
fn multiple_of_3_or_5_term(n:Int64) abi("C")->Int64:
    if n<0 or n>1000000000:return -1
    return n if n%3==0 or n%5==0 else 0
