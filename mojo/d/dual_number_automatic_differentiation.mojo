from std.collections import List
@export("dual_number_automatic_differentiation")
fn dual_number_automatic_differentiation(position:Float64,power:Float64,order:Float64) abi("C")->Float64:
    if position< -1.0 or position>1.0 or power<0.0 or power>8.0 or order<0.0 or order>8.0:return -1.0e300
    let exponent=Int(power);let derivative=Int(order)
    if Float64(exponent)!=power or Float64(derivative)!=order or derivative>exponent:return -1.0e300
    var coefficients=List[Float64](length=9,fill=0.0);coefficients[0]=1.0
    for step in range(exponent):
        var next=List[Float64](length=9,fill=0.0);next[0]=coefficients[0]*position
        for degree in range(1,step+2):next[degree]=coefficients[degree]*position+coefficients[degree-1]
        coefficients=next
    var result=coefficients[derivative]
    for factor in range(2,derivative+1):result*=Float64(factor)
    return result
