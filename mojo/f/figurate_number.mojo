fn figurate_triangular(n: Int64) -> Bool:
    for i in range(n + 1):
        let term = i * (i + 1) / 2
        if term == n: return True
        if term > n: return False
    return False

fn figurate_tetrahedral(n: Int64) -> Bool:
    for i in range(1, n + 1):
        let term = i * (i + 1) * (i + 2) / 6
        if term == n: return True
        if term > n: return False
    return False

fn figurate_pentatope(n: Int64) -> Bool:
    for i in range(1, n + 1):
        let term = i * (i + 1) * (i + 2) * (i + 3) / 24
        if term == n: return True
        if term > n: return False
    return False

@export("figurate_number")
fn figurate_number(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 1000000: return -1
    return (1 if figurate_triangular(n) else 0) + (2 if figurate_tetrahedral(n) else 0) + (4 if figurate_pentatope(n) else 0)
