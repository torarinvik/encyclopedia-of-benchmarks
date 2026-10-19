fn p5_gcd(a_in:Int64,b_in:Int64)->Int64:
    var a=a_in;var b=b_in
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("problem5")
fn problem5(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>20:return -1
    var result=Int64(1)
    for n in range(1,Int(limit+1)):result=result//p5_gcd(result,Int64(n))*Int64(n)
    return result
