fn p112_bouncy(value_in:Int64)->Bool:
    var value=value_in;var prev=value%10;value//=10;var inc=False;var dec=False
    while value>0:
        let digit=value%10
        if digit<prev:inc=True
        if digit>prev:dec=True
        prev=digit;value//=10
    return inc and dec
@export("problem112")
fn problem112(percent:Int64) abi("C")->Int64:
    if percent<1 or percent>99:return -1
    var b=Int64(0);var n=Int64(1)
    while True:
        if p112_bouncy(n):b+=1
        if b*100>=percent*n:return n
        n+=1
    return -1
