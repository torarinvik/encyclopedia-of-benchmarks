@export("binomial_dist")
fn binomial_dist(n: Float64, p: Float64, x: Float64) abi("C") -> Float64:
    if n < 1.0 or n > 16.0 or x < 1.0 or x > n or n != Float64(Int(n)) or x != Float64(Int(x)) or (p != 0.25 and p != 0.5 and p != 0.75): return -1.0
    let ni = Int(n); let xi = Int(x)
    var numerator = n; var denominator = x
    var i = ni - 1
    while i >= ni - xi + 1: numerator *= Float64(i); i -= 1
    i = 1
    while i < xi: denominator *= Float64(i); i += 1
    var px = 1.0; for _ in range(xi): px *= p
    var qx = 1.0; for _ in range(ni - xi): qx *= (1.0 - p)
    return (numerator / denominator) * px * qx
