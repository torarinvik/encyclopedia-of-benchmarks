@export("strong_number")
fn strong_number(x:Int64) abi("C")->Int64:
    if x< -2147483648 or x>2147483647:return -1
    if x<0:return 0
    var rem=x;var sum:Int64=0
    if rem==0:sum=1
    while rem>0:
        let d=rem%10;var fact:Int64=1
        for k in range(2,Int(d)+1):fact*=k
        sum+=fact;rem/=10
    return 1 if sum==x else 0
