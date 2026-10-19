@export("sum_of_odd_numbers")
fn sum_of_odd_numbers(n:Int64) abi("C")->Int64:
    if n<0 or n>46340:return -1
    return n*n
