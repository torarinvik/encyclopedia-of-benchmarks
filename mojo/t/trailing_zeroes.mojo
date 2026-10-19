@export("trailing_zeroes")
fn trailing_zeroes(n:Int64) abi("C")->Int64:
    if n<0:return -1
    if n==0:return 1
    var x=n;var count=0
    while x%10==0:count+=1;x/=10
    return count
