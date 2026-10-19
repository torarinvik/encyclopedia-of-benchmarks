@export("kth_factor")
fn kth_factor(n:Int64,k:Int64) abi("C")->Int64:
    if n<1 or n>10000 or k<1 or k>n:return -1
    var count:Int64=0
    for i in range(1,Int(n)+1):if n%Int64(i)==0:count+=1;if count==k:return i
    return -1
