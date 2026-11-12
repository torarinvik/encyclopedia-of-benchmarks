from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

from std.collections import InlineArray

fn mmc_ratio_less(a_num: Int64, a_den: Int64, b_num: Int64, b_den: Int64) -> Bool:
    return a_num * b_den < b_num * a_den

fn mmc_gcd(a_value: Int64, b_value: Int64) -> Int64:
    var a = a_value
    var b = b_value
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

fn mmc_reachable(n: Int, adjacency: InlineArray[Bool, 64], reverse: Bool) -> Bool:
    var seen = InlineArray[Bool, 8](fill=False)
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 1
    seen[0] = True
    queue[0] = 0
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            let slot = if reverse { v * 8 + u } else { u * 8 + v }
            if adjacency[slot] and not seen[v]:
                seen[v] = True
                queue[tail] = v
                tail += 1
    for v in range(n):
        if not seen[v]: return False
    return True

fn mmc_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("minimum_mean_cycle_karp")
fn minimum_mean_cycle_karp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 51: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > 8 or m_value < 1 or m_value > 16: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if m > n * n or length != c_size_t(2 + 3 * m): return -1

    var edge_from = InlineArray[Int, 16](fill=0)
    var edge_to = InlineArray[Int, 16](fill=0)
    var edge_weight = InlineArray[Int64, 16](fill=0)
    var adjacent = InlineArray[Bool, 64](fill=False)
    for edge in range(m):
        let u_value = input[2 + 3 * edge]
        let v_value = input[3 + 3 * edge]
        let weight = input[4 + 3 * edge]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or weight < -1000 or weight > 1000:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        let slot = u * 8 + v
        if adjacent[slot]: return -1
        adjacent[slot] = True
        edge_from[edge] = u
        edge_to[edge] = v
        edge_weight[edge] = weight
    if not mmc_reachable(n, adjacent, False) or not mmc_reachable(n, adjacent, True): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2

    var cost = InlineArray[Int64, 72](fill=0)
    var reachable = InlineArray[Bool, 72](fill=False)
    reachable[0] = True
    for k in range(1, n + 1):
        for edge in range(m):
            let u = edge_from[edge]
            let v = edge_to[edge]
            let previous = (k - 1) * 8 + u
            let current = k * 8 + v
            if not reachable[previous]: continue
            let candidate = cost[previous] + edge_weight[edge]
            if not reachable[current] or candidate < cost[current]:
                reachable[current] = True
                cost[current] = candidate

    var have_answer = False
    var answer_num: Int64 = 0
    var answer_den: Int64 = 1
    for v in range(n):
        if not reachable[n * 8 + v]: continue
        var have_local = False
        var local_num: Int64 = 0
        var local_den: Int64 = 1
        for k in range(n):
            let slot = k * 8 + v
            if not reachable[slot]: continue
            let numerator = cost[n * 8 + v] - cost[slot]
            let denominator = Int64(n - k)
            if not have_local or mmc_ratio_less(local_num, local_den, numerator, denominator):
                local_num = numerator
                local_den = denominator
                have_local = True
        if have_local and (not have_answer or mmc_ratio_less(local_num, local_den, answer_num, answer_den)):
            answer_num = local_num
            answer_den = local_den
            have_answer = True
    if not have_answer: return -1
    let absolute_num = if answer_num < 0 { -answer_num } else { answer_num }
    let divisor = mmc_gcd(absolute_num, answer_den)
    answer_num /= divisor
    answer_den /= divisor
    var staged = InlineArray[UInt8, 16](fill=0)
    mmc_store_i64_le(staged.unsafe_ptr(), 0, answer_num)
    mmc_store_i64_le(staged.unsafe_ptr(), 8, answer_den)
    for byte in range(16): output[byte] = staged[byte]
    return 16
