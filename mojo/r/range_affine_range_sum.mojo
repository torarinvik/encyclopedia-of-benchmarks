from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(998244353)
comptime MAX_LENGTH = 64
comptime MAX_OPERATIONS = 64
comptime TREE_NODES = 256
comptime MAX_PARSEABLE_INPUT = 387

fn aff_apply(sum: UnsafePointer[Int64, MutAnyOrigin], mul: UnsafePointer[Int64, MutAnyOrigin],
             add: UnsafePointer[Int64, MutAnyOrigin], node: Int, length: Int, a: Int64, b: Int64):
    sum[node] = (a * sum[node] + b * length) % MODULUS
    mul[node] = (a * mul[node]) % MODULUS
    add[node] = (a * add[node] + b) % MODULUS

fn aff_push(sum: UnsafePointer[Int64, MutAnyOrigin], mul: UnsafePointer[Int64, MutAnyOrigin],
            add: UnsafePointer[Int64, MutAnyOrigin], node: Int, left: Int, right: Int):
    if right - left <= 1 or (mul[node] == 1 and add[node] == 0): return
    let middle = left + (right - left) / 2
    let a = mul[node]
    let b = add[node]
    aff_apply(sum, mul, add, node * 2, middle - left, a, b)
    aff_apply(sum, mul, add, node * 2 + 1, right - middle, a, b)
    mul[node] = 1
    add[node] = 0

fn aff_build(sum: UnsafePointer[Int64, MutAnyOrigin], values: UnsafePointer[Int64, MutAnyOrigin],
             node: Int, left: Int, right: Int):
    if right - left == 1:
        sum[node] = values[left]
        return
    let middle = left + (right - left) / 2
    aff_build(sum, values, node * 2, left, middle)
    aff_build(sum, values, node * 2 + 1, middle, right)
    sum[node] = (sum[node * 2] + sum[node * 2 + 1]) % MODULUS

fn aff_update(sum: UnsafePointer[Int64, MutAnyOrigin], mul: UnsafePointer[Int64, MutAnyOrigin],
              add: UnsafePointer[Int64, MutAnyOrigin], ql: Int, qr: Int, node: Int,
              left: Int, right: Int, a: Int64, b: Int64):
    if ql <= left and right <= qr:
        aff_apply(sum, mul, add, node, right - left, a, b)
        return
    if qr <= left or right <= ql: return
    aff_push(sum, mul, add, node, left, right)
    let middle = left + (right - left) / 2
    aff_update(sum, mul, add, ql, qr, node * 2, left, middle, a, b)
    aff_update(sum, mul, add, ql, qr, node * 2 + 1, middle, right, a, b)
    sum[node] = (sum[node * 2] + sum[node * 2 + 1]) % MODULUS

fn aff_query(sum: UnsafePointer[Int64, MutAnyOrigin], mul: UnsafePointer[Int64, MutAnyOrigin],
             add: UnsafePointer[Int64, MutAnyOrigin], ql: Int, qr: Int, node: Int,
             left: Int, right: Int) -> Int64:
    if ql <= left and right <= qr: return sum[node]
    if qr <= left or right <= ql: return 0
    aff_push(sum, mul, add, node, left, right)
    let middle = left + (right - left) / 2
    return (aff_query(sum, mul, add, ql, qr, node * 2, left, middle) +
            aff_query(sum, mul, add, ql, qr, node * 2 + 1, middle, right)) % MODULUS

@export("range_affine_range_sum_benchmark")
fn range_affine_range_sum_benchmark(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_LENGTH: return -1
    let n = Int(n_value)
    if length < c_size_t(n + 2): return -1
    var values = InlineArray[Int64, MAX_LENGTH]()
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] >= MODULUS: return -1
        values[i] = input[i + 1]
    let q_value = input[n + 1]
    if q_value < 1 or q_value > MAX_OPERATIONS: return -1
    let q = Int(q_value)
    var sums = InlineArray[Int64, TREE_NODES]()
    var lazy_mul = InlineArray[Int64, TREE_NODES]()
    var lazy_add = InlineArray[Int64, TREE_NODES]()
    for i in range(TREE_NODES): lazy_mul[i] = 1
    aff_build(sums.unsafe_ptr(), values.unsafe_ptr(), 1, 0, n)

    var cursor = n + 2
    var checksum = Int64(0)
    for operation in range(q):
        if c_size_t(cursor) >= length: return -1
        let opcode = input[cursor]
        cursor += 1
        if opcode == 0:
            if c_size_t(cursor + 4) > length: return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            let a = input[cursor + 2]
            let b = input[cursor + 3]
            cursor += 4
            if left < 0 or left >= right or right > n_value or a < 1 or a >= MODULUS or b < 0 or b >= MODULUS:
                return -1
            aff_update(sums.unsafe_ptr(), lazy_mul.unsafe_ptr(), lazy_add.unsafe_ptr(),
                       Int(left), Int(right), 1, 0, n, a, b)
        elif opcode == 1:
            if c_size_t(cursor + 2) > length: return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            cursor += 2
            if left < 0 or left >= right or right > n_value: return -1
            let result = aff_query(sums.unsafe_ptr(), lazy_mul.unsafe_ptr(), lazy_add.unsafe_ptr(),
                                   Int(left), Int(right), 1, 0, n)
            checksum += Int64(operation + 1) * (result + MODULUS)
        else:
            return -1
    if c_size_t(cursor) == length: return checksum
    return -1
