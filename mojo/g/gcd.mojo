@export("gcd")
fn gcd(left:UInt64,right:UInt64) abi("C")->Int64:
    var a=left;var b=right
    while b!=0:
        let rem=a%b;a=b;b=rem
    return Int64(a)
