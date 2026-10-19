fn decimal_binary_recursive(value:Int64)->Int64:
    if value==0:return 0
    return value%2+10*decimal_binary_recursive(value/2)
@export("decimal_to_binary_recursion")
fn decimal_to_binary_recursion(value:Int64) abi("C")->Int64:
    if value<0 or value>1023:return -1
    return decimal_binary_recursive(value)
