@export("narcissistic_number_checker")
fn narcissistic_number_checker(x:Int64) abi("C")->Int64:
    if x< -2147483648 or x>999999:return -1
    if x<0:return 0
    var digits=0;var tmp=x
    while tmp>0:digits+=1;tmp//=10
    var sum:Int64=0;tmp=x
    while tmp>0:
        let d=tmp%10;var p:Int64=1
        for _ in range(digits):p*=d
        sum+=p;tmp//=10
    return 1 if sum==x else 0
