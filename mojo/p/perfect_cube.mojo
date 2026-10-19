@export("perfect_cube")
fn perfect_cube(x:Int64) abi("C")->Int64:
    if x < -1000000000000 or x>1000000000000:return -1
    let target=if x<0:-x else:x;var lo:Int64=0;var hi:Int64=10000
    while lo<=hi:let mid=lo+(hi-lo)/2;let cube=mid*mid*mid;if cube==target:return 1 elif cube<target:lo=mid+1 else:hi=mid-1
    return 0
