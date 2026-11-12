from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime BK_MODULUS: Int64 = 998244353
comptime BK_MAX_N = 32
comptime BK_MAX_INPUT = 66
comptime BK_MAX_BLOCKS = 6
comptime BK_MAX_POWERS = 7

fn bk_multiply(left: InlineArray[Int64, 32], right: InlineArray[Int64, 32], n: Int,
               inout product: InlineArray[Int64, 32]):
    for degree in range(n): product[degree] = 0
    for i in range(n):
        for j in range(n - i):
            product[i + j] = (product[i + j] + left[i] * right[j]) % BK_MODULUS

fn bk_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("brent_kung_fps_composition")
fn brent_kung_fps_composition(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > BK_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > BK_MAX_N: return -1
    let n = Int(n_value)
    if Int(length) != 1 + 2 * n: return -1
    for i in range(2 * n):
        if input[i + 1] < 0 or input[i + 1] >= BK_MODULUS: return -1
    if input[1 + n] != 0: return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2

    var blockSize = 1
    while blockSize * blockSize < n: blockSize += 1
    let blockCount = (n + blockSize - 1) // blockSize
    var powers = InlineArray[Int64, 224]()
    var blocks = InlineArray[Int64, 192]()
    var inner = InlineArray[Int64, 32]()
    var left = InlineArray[Int64, 32]()
    var right = InlineArray[Int64, 32]()
    var product = InlineArray[Int64, 32]()
    var composed = InlineArray[Int64, 32]()
    for degree in range(n): inner[degree] = input[1 + n + degree]
    powers[0] = 1
    for exponent in range(1, blockSize + 1):
        for degree in range(n): left[degree] = powers[(exponent - 1) * BK_MAX_N + degree]
        bk_multiply(left, inner, n, inout product)
        for degree in range(n): powers[exponent * BK_MAX_N + degree] = product[degree]
    for block in range(blockCount):
        for offset in range(blockSize):
            let coefficientIndex = block * blockSize + offset
            if coefficientIndex >= n: break
            let coefficient = input[1 + coefficientIndex]
            for degree in range(n):
                let blockIndex = block * BK_MAX_N + degree
                blocks[blockIndex] =
                    (blocks[blockIndex] + coefficient * powers[offset * BK_MAX_N + degree]) % BK_MODULUS
    for degree in range(n): composed[degree] = blocks[(blockCount - 1) * BK_MAX_N + degree]
    var block = blockCount - 1
    while block > 0:
        for degree in range(n):
            left[degree] = composed[degree]
            right[degree] = powers[blockSize * BK_MAX_N + degree]
        bk_multiply(left, right, n, inout product)
        for degree in range(n):
            composed[degree] = (product[degree] + blocks[(block - 1) * BK_MAX_N + degree]) % BK_MODULUS
        block -= 1
    for degree in range(n): bk_store_le(output, 8 * degree, composed[degree])
    return Int64(bytes)
