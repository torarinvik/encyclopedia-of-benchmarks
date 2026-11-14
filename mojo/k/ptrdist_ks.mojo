# Independent bounded Kernighan–Lin profile; source provenance in package README.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ks_count(value: Int) -> Int:
    var bits = value
    var count = 0
    while bits != 0: count += bits & 1; bits >>= 1
    return count

fn ks_cut(side: Int, nets: List[Int]) -> Int:
    var total = 0
    for net in nets:
        let a = ks_count(net & side)
        let b = ks_count(net & ~side)
        total += a*b
    return total

@export("ptrdist_ks")
fn ptrdist_ks(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 146: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 2 or nv > 8 or nv%2 != 0 or mv < 0 or mv > 16: return -1
    let n = Int(nv); let m = Int(mv); let half = n//2
    var nets = List[Int](capacity=m)
    var cursor = 2
    for _ in range(m):
        if c_size_t(cursor) >= length: return -1
        let degree = input[cursor]
        cursor += 1
        if degree < 2 or degree > nv or c_size_t(cursor+Int(degree)) > length: return -1
        var mask = 0
        for _ in range(Int(degree)):
            let member = input[cursor]
            cursor += 1
            if member < 0 or member >= nv or (mask & (1 << Int(member))) != 0: return -1
            mask |= 1 << Int(member)
        nets.append(mask)
    if c_size_t(cursor) != length: return -1
    var order_a = List[Int](capacity=half)
    var order_b = List[Int](capacity=half)
    for i in range(half): order_a.append(i); order_b.append(half+i)
    var side = (1 << half)-1
    var accepted = Int64(0)
    while True:
        var work = side
        var remaining_a = List[Int](capacity=half)
        var remaining_b = List[Int](capacity=half)
        for i in range(half): remaining_a.append(order_a[i]); remaining_b.append(order_b[i])
        var selected_a = List[Int](capacity=half)
        var selected_b = List[Int](capacity=half)
        var cumulative = 0
        var best_gain = -1000000
        var best_prefix = 0
        for step in range(half):
            let baseline = ks_cut(work,nets)
            var pair_gain = -1000000
            var chosen_a = 0; var chosen_b = 0
            for a in remaining_a:
                for b in remaining_b:
                    let swapped = work ^ (1 << a) ^ (1 << b)
                    let gain = baseline-ks_cut(swapped,nets)
                    if gain > pair_gain: pair_gain = gain; chosen_a = a; chosen_b = b
            selected_a.append(chosen_a); selected_b.append(chosen_b)
            work ^= (1 << chosen_a) | (1 << chosen_b)
            var ai = 0; var bi = 0
            while remaining_a[ai] != chosen_a: ai += 1
            while remaining_b[bi] != chosen_b: bi += 1
            for i in range(ai,len(remaining_a)-1): remaining_a[i] = remaining_a[i+1]
            for i in range(bi,len(remaining_b)-1): remaining_b[i] = remaining_b[i+1]
            _ = remaining_a.pop(); _ = remaining_b.pop()
            cumulative += pair_gain
            if cumulative > best_gain: best_gain = cumulative; best_prefix = step+1
        if best_gain <= 0: break
        side = 0
        for i in range(half):
            if i < best_prefix: order_a[i] = selected_b[i]; order_b[i] = selected_a[i]
            else: order_a[i] = selected_a[i]; order_b[i] = selected_b[i]
            side |= 1 << order_a[i]
        accepted += 1
    var cut_nets = 0
    for net in nets:
        if (net & side) != 0 and (net & ~side) != 0: cut_nets += 1
    return Int64(side)+(Int64(ks_cut(side,nets)) << 8)+(Int64(cut_nets) << 17)+(accepted << 22)
