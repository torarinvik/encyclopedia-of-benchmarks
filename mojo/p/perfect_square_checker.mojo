@export("perfect_square_checker")
fn perfect_square_checker(x:Int64) abi("C")->Int64:
    if x < -2147483648 or x>2147483647:return -1
    if x<0:return 0
    var lo:Int64=0;var hi:Int64=46340
    while lo<=hi:let mid=lo+(hi-lo)/2;let sq=mid*mid;if sq==x:return 1 elif sq<x:lo=mid+1 else:hi=mid-1
    return 0
