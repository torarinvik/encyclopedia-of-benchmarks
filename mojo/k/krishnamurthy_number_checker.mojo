@export("krishnamurthy_number_checker")
fn krishnamurthy_number_checker(x:Int64) abi("C")->Int64:
    if x< -2147483648 or x>2147483647:return -1
    if x<=0:return 0
    var fs=InlineArray[Int64,10]();fs[0]=1
    for i in range(1,10):fs[i]=fs[i-1]*i
    var v=x;var sum:Int64=0
    while v>0:sum+=fs[Int(v%10)];v//=10
    return 1 if sum==x else 0
