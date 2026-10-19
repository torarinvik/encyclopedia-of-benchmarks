from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bm_determinant(features: List[List[Int64]], columns: List[Int]) -> Int64:
    var paths = List[Int64](capacity=32); for _ in range(32): paths.append(0)
    paths[0] = 1
    for row in range(5):
        var next = List[Int64](capacity=32); for _ in range(32): next.append(0)
        for mask in range(32):
            if len_bits(mask) != row or paths[mask] == 0: continue
            for column in range(5):
                let bit = 1 << column
                if (mask & bit) != 0: continue
                var inversions = 0
                for previous in range(column + 1, 5):
                    if (mask & (1 << previous)) != 0: inversions += 1
                let term = paths[mask] * features[row][columns[column]]
                next[mask | bit] += term if inversions % 2 == 0 else -term
        paths = next
    return paths[31]

fn len_bits(value0: Int) -> Int:
    var value = value0; var count = 0
    while value > 0: count += value & 1; value >>= 1
    return count

@export("braikenridge_maclaurin_construction")
fn braikenridge_maclaurin_construction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 10: return -2
    var features = List[List[Int64]](capacity=5)
    for p in range(5):
        let x = input[2 * p]; let y = input[2 * p + 1]
        if x < -10 or x > 10 or y < -10 or y > 10: return -2
        var row = List[Int64](capacity=6); row.append(x * x); row.append(x * y); row.append(y * y); row.append(x); row.append(y); row.append(1)
        features.append(row)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 48: return -2
    var masks = List[Int](capacity=30)
    for value in [1,2,3,4,5, 0,2,3,4,5, 0,1,3,4,5, 0,1,2,4,5, 0,1,2,3,5, 0,1,2,3,4]: masks.append(value)
    for c in range(6):
        var cols = List[Int](capacity=5); for j in range(5): cols.append(masks[c * 5 + j])
        let det = bm_determinant(features, cols); let signed = det if c % 2 == 0 else -det; let bits = UInt64(signed)
        for b in range(8): output[c * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return 6
