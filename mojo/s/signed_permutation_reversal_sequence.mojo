from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn signed_reversal_encode(p: List[Int], n: Int) -> Int:
    var rank = 0; var signs = 0
    for i in range(n):
        var value = p[i]
        if value < 0: value = -value; signs |= 1 << (value-1)
        var smaller = 0
        for j in range(i+1,n):
            var other = p[j]
            if other < 0: other = -other
            if other < value: smaller += 1
        rank = rank*(n-i)+smaller
    return rank*(1 << n)+signs

fn signed_reversal_decode(state: Int, n: Int, factorials: List[Int]) -> List[Int]:
    let sign_count = 1 << n
    var rank = state//sign_count
    let signs = state%sign_count
    var available = List[Int](capacity=n)
    var result = List[Int](capacity=n)
    for i in range(n): available.append(i+1)
    for i in range(n):
        let factor = factorials[n-i-1]
        let digit = rank//factor
        rank %= factor
        let value = available[digit]
        for j in range(digit,len(available)-1): available[j] = available[j+1]
        _ = available.pop()
        if (signs & (1 << (value-1))) != 0: result.append(-value)
        else: result.append(value)
    return result

@export("signed_permutation_reversal_sequence")
fn signed_permutation_reversal_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 6: return -1
    let nv = input[0]
    if nv < 2 or nv > 5 or length != c_size_t(nv+1): return -1
    let n = Int(nv)
    var permutation = List[Int](capacity=n)
    var seen = 0
    for i in range(n):
        let raw = input[i+1]
        if raw == 0 or raw < -nv or raw > nv: return -1
        var value = Int(raw)
        if value < 0: value = -value
        if (seen & (1 << (value-1))) != 0: return -1
        seen |= 1 << (value-1)
        permutation.append(Int(raw))
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var factorials = List[Int](capacity=6)
    factorials.append(1); factorials.append(1); factorials.append(2); factorials.append(6); factorials.append(24); factorials.append(120)
    let states = factorials[n]*(1 << n)
    var parent = List[Int](length=states, fill=-2)
    var move_left = List[Int](length=states, fill=0)
    var move_right = List[Int](length=states, fill=0)
    var queue = List[Int](capacity=states)
    let start = signed_reversal_encode(permutation,n)
    parent[start] = -1; queue.append(start)
    var head = 0
    while head < len(queue) and parent[0] == -2:
        let current = queue[head]; head += 1
        let old = signed_reversal_decode(current,n,factorials)
        for left in range(n):
            if parent[0] != -2: break
            for right in range(left,n):
                var next_p = List[Int](capacity=n)
                for value in old: next_p.append(value)
                var a = left; var b = right
                while a < b:
                    let x = next_p[a]; let y = next_p[b]
                    next_p[a] = -y; next_p[b] = -x
                    a += 1; b -= 1
                if a == b: next_p[a] = -next_p[a]
                let next = signed_reversal_encode(next_p,n)
                if parent[next] != -2: continue
                parent[next] = current; move_left[next] = left+1; move_right[next] = right+1
                queue.append(next)
                if next == 0: break
    if parent[0] == -2: return -1
    var lefts = List[Int](capacity=10); var rights = List[Int](capacity=10)
    var current = 0
    while parent[current] >= 0:
        if len(lefts) == 10: return -1
        lefts.append(move_left[current]); rights.append(move_right[current])
        current = parent[current]
    let count = len(lefts); let bytes = 8*(1+2*count)
    if capacity < c_size_t(bytes): return -2
    for i in range(1+2*count):
        var value = Int64(count)
        if i > 0:
            let index = count-1-(i-1)//2
            if (i & 1) == 1: value = Int64(lefts[index])
            else: value = Int64(rights[index])
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
