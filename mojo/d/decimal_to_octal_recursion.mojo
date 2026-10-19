fn decimal_octal_recursive(value:Int64)->Int64:
    if value==0:return 0
    return decimal_octal_recursive(value/8)*10+value%8
@export("decimal_to_octal_recursion")
fn decimal_to_octal_recursion(value:Int64) abi("C")->Int64:
    if value<0 or value>295600127:return -1
    return decimal_octal_recursive(value)
