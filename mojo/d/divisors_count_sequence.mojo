@export("divisors_count_sequence")
fn divisors_count_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>9999:return -1
    let n=index+1
    if n==1:return 1
    var count:Int64=2
    for k in range(2,Int(n)):if n%Int64(k)==0:count+=1
    return count
