@export("binomial_sequence")
fn binomial_sequence(index: Int64) abi("C") -> Int64:
    if index < 0 or index > 230: return -1
    var row = 0; var start = 0
    while index >= start + row + 1: start += row + 1; row += 1
    let k = Int(index - start); var coeff: Int64 = 1
    for j in range(1, k + 1): coeff = (coeff * (row - j + 1)) // j
    return coeff
