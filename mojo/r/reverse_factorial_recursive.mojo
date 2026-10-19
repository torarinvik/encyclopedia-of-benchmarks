fn reverse_factorial_impl(v:Int64,d:Int64)->Int64:
    if v==1:return if d==1:1 else:d-1
    if v%d!=0:return -1
    return reverse_factorial_impl(v/d,d+1)
@export("reverse_factorial_recursive")
fn reverse_factorial_recursive(v:Int64) abi("C")->Int64:
    if v<1:return -1
    return reverse_factorial_impl(v,1)
