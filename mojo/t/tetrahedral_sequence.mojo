@export("tetrahedral_sequence")
fn tetrahedral_sequence(n:Int64) abi("C")->Int64:
    if n<0 or n>3810777:return -1
    var a=n;var b=n+1;var c=n+2
    if a%2==0:a/=2
    elif b%2==0:b/=2
    else:c/=2
    if a%3==0:a/=3
    elif b%3==0:b/=3
    else:c/=3
    return a*b*c
