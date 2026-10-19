fn lucas_rec(n:Int64)->Int64:
    if n==0:return 2
    if n==1:return 1
    return lucas_rec(n-1)+lucas_rec(n-2)
@export("lucas_series_recursive")
fn lucas_series_recursive(n:Int64) abi("C")->Int64:
    if n<0 or n>25:return -1
    return lucas_rec(n)
