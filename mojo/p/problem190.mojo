from std.math import pow
@export("problem190")
fn problem190(n:Int64) abi("C")->Int64:
    if n<0 or n>15:return -1
    var total=Int64(0)
    for m in range(2,Int(n+1)):
        let x1=2.0/Float64(m+1);var product=Float64(1.0)
        for i in range(1,m+1):
            let xi=Float64(i)*x1;product*=pow(xi,Float64(i))
        total+=Int64(product)
    return total
