@export("lucas_series")
fn lucas_series(n:Int64) abi("C")->Int64:
    if n<0 or n>90:return -1
    if n==0:return 2
    var a:Int64=2;var b:Int64=1
    for _ in range(2,Int(n)+1):let t=a+b;a=b;b=t
    return b
