from std.math import pow

@export("exponential_function")
fn exponential_function(power:Float64,term_count:Float64) abi("C")->Float64:
    if power!=power or term_count!=term_count or power< -10.0 or power>10.0 or term_count<0.0 or term_count>32.0 or Float64(Int64(term_count))!=term_count:return -1.0e300
    let n=Int(term_count)
    if n==0:return 1.0
    var output:Float64=0.0;var factorial:Float64=1.0
    for i in range(n):output+=pow(power,Float64(i))/factorial;factorial*=Float64(i+1)
    return output
