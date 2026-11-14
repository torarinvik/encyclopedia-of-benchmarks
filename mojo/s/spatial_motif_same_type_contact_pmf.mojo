from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn spatial_choose(n: Int64, k0: Int64) -> Int64:
    if k0 < 0 or k0 > n: return 0
    var k = k0
    if n - k < k: k = n - k
    var result = Int64(1)
    for i in range(1, Int(k) + 1):
        result = result * (n - k + Int64(i)) // Int64(i)
    return result

fn spatial_gcd(mut a: Int64, mut b: Int64) -> Int64:
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

@export("spatial_motif_same_type_contact_pmf")
fn spatial_motif_same_type_contact_pmf(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let size = input[0]; let x1 = input[1]; let x2 = input[2]
    if size < 1 or size > 16 or x1 < 0 or x1 > size or x2 < 0 or x2 > size: return -1
    var low = x1 + x2 - size
    if low < 0: low = 0
    var high = x1
    if x2 < high: high = x2
    var words = List[Int64]()
    words.append(low); words.append(high); words.append(spatial_choose(size, x2))
    for i in range(Int(low), Int(high) + 1):
        words.append(spatial_choose(x1, Int64(i)) * spatial_choose(size - x1, x2 - Int64(i)))
    let numerator = x1 * x2
    let divisor = spatial_gcd(numerator, size)
    words.append(numerator // divisor); words.append(size // divisor)
    let bytes = 8 * len(words)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(len(words)):
        for byte in range(8): output[8 * word + byte] = UInt8((words[word] >> (8 * byte)) & 255)
    return Int64(bytes)
