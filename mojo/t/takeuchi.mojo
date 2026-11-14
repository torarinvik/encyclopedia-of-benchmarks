fn takeuchi_recursive(x: Int64, y: Int64, z: Int64) -> Int64:
    if y < x:
        let a = takeuchi_recursive(x - 1, y, z)
        let b = takeuchi_recursive(y - 1, z, x)
        let c = takeuchi_recursive(z - 1, x, y)
        return takeuchi_recursive(a, b, c)
    return z

@export("takeuchi")
fn takeuchi(x: Int64, y: Int64, z: Int64) abi("C") -> Int64:
    if x < 0 or x > 12 or y < 0 or y > 12 or z < 0 or z > 12:
        return -1
    return takeuchi_recursive(x, y, z)
