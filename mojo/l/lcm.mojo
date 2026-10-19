@export("lcm")
fn lcm(a:UInt64,b:UInt64) abi("C")->Int64:
    if a==0 or b==0:return 0
    var x=a;var y=b
    while y!=0:let r=x%y;x=y;y=r
    let reduced=a/x;let limit=UInt64(9223372036854775807)
    if reduced>limit/b:return -1
    return Int64(reduced*b)
