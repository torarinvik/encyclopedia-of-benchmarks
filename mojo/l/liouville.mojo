@export("liouville")
fn liouville(n:Int64) abi("C")->Int64:
    if n<1 or n>2147483647:return -2
    var rem=UInt64(n);var sign:Int64=1;var p=UInt64(2)
    while p<=rem/p:
        if rem%p==0:
            sign= -sign
            while rem%p==0:rem/=p
        p+=if p==2:1 else:2
    if rem>1:sign= -sign
    return sign
