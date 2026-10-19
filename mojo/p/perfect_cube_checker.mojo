@export("perfect_cube_checker")
fn perfect_cube_checker(x:Int64) abi("C")->Int64:
    if x < -2147483648 or x>2147483647:return -1
    let target=if x<0:-x else:x;var lo:Int64=0;var hi:Int64=1290
    while lo<=hi:let mid=lo+(hi-lo)/2;let cube=mid*mid*mid;if cube==target:return 1 elif cube<target:lo=mid+1 else:hi=mid-1
    return 0
