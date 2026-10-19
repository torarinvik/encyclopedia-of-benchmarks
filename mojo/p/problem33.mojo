fn p33_gcd(left_in:Int64,right_in:Int64)->Int64:
    var left=left_in;var right=right_in
    while right!=0:let r=left%right;left=right;right=r
    return left
@export("problem33")
fn problem33(digit_len:Int64) abi("C")->Int64:
    if digit_len<0 or digit_len>5:return -1
    var upper=Int64(1)
    for _ in range(Int(digit_len)):upper*=10
    var result=Float64(1.0);var denominator=Int64(11)
    for numerator in range(11,Int(upper)):
        while denominator<=99:
            if Int64(numerator)!=denominator and Int64(numerator)%10==denominator//10 and denominator%10!=0 and Float64(Int64(numerator)//10)/Float64(denominator%10)==Float64(numerator)/Float64(denominator):
                let divisor=p33_gcd(Int64(numerator),denominator)
                result*=Float64(denominator//divisor)/Float64(Int64(numerator)//divisor)
            denominator+=1
        denominator=10
    return Int64(result)
