@export("perrin_number")
fn perrin_number(n:Int64) abi("C")->Int64:
    if n<0 or n>155:return -1
    if n==0:return 3
    if n==1:return 0
    if n==2:return 2
    var a:Int64=3;var b:Int64=0;var c:Int64=2;var result:Int64=0
    for _ in range(3,Int(n)+1):result=a+b;a=b;b=c;c=result
    return result
