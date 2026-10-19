@export("tetranacci_numbers_sequence")
fn tetranacci_numbers_sequence(n:Int64) abi("C")->Int64:
    if n<0 or n>68:return -1
    if n<=3:return 1
    var a:Int64=1;var b:Int64=1;var c:Int64=1;var d:Int64=1
    for _ in range(4,Int(n)+1):
        let x=a+b+c+d;a=b;b=c;c=d;d=x
    return d
