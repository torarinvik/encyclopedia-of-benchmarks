@export("tribonacci_numbers_sequence")
fn tribonacci_numbers_sequence(n:Int64) abi("C")->Int64:
    if n<0 or n>60:return -1
    var a:Int64=1;var b:Int64=1;var c:Int64=1
    if n==0:return a
    if n==1:return b
    for _ in range(2,Int(n)+1):let d=a+b+c;a=b;b=c;c=d
    return c
