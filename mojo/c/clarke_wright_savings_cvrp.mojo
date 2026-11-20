from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("clarke_wright_savings_cvrp")
fn clarke_wright_savings_cvrp(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 74:
        return -1
    let n64 = input[0]
    let cap64 = input[1]
    if n64 < 0 or n64 > 7 or cap64 < 1 or cap64 > 100: return -1
    let n = Int(n64)
    let cap = Int(cap64)
    let width = n + 1
    if Int(length) != 2 + n + width * width: return -1

    var demand = InlineArray[Int64, 8](fill=0)
    for c in range(1, n + 1):
        demand[c] = input[1 + c]
        if demand[c] < 1 or demand[c] > cap64: return -1
    var distance = InlineArray[Int64, 64](fill=0)
    let offset = 2 + n
    for i in range(width):
        for j in range(width):
            let d = input[offset + i * width + j]
            if d < 0 or d > 1000 or (i == j and d != 0): return -1
            distance[i * 8 + j] = d
    for i in range(width):
        for j in range(i + 1, width):
            if distance[i * 8 + j] != distance[j * 8 + i]: return -1

    var routes = InlineArray[Int, 49](fill=0)
    var route_length = InlineArray[Int, 7](fill=0)
    var load = InlineArray[Int64, 7](fill=0)
    var active = InlineArray[Bool, 7](fill=False)
    for r in range(n):
        routes[r * 7] = r + 1
        route_length[r] = 1
        load[r] = demand[r + 1]
        active[r] = True
    var savings = InlineArray[Int64, 21](fill=0)
    var pair_i = InlineArray[Int, 21](fill=0)
    var pair_j = InlineArray[Int, 21](fill=0)
    var pair_count = 0
    for i in range(1, n + 1):
        for j in range(i + 1, n + 1):
            savings[pair_count] = distance[i] + distance[j] - distance[i * 8 + j]
            pair_i[pair_count] = i
            pair_j[pair_count] = j
            pair_count += 1
    for i in range(pair_count):
        for j in range(i + 1, pair_count):
            let before = savings[j] > savings[i] or (
                savings[j] == savings[i] and (pair_i[j] < pair_i[i] or
                (pair_i[j] == pair_i[i] and pair_j[j] < pair_j[i])))
            if before:
                let sv = savings[i]; savings[i] = savings[j]; savings[j] = sv
                let ai = pair_i[i]; pair_i[i] = pair_i[j]; pair_i[j] = ai
                let aj = pair_j[i]; pair_j[i] = pair_j[j]; pair_j[j] = aj

    for p in range(pair_count):
        if savings[p] <= 0: break
        var ri = -1; var rj = -1; var pi = -1; var pj = -1
        for r in range(n):
            if active[r]:
                for at in range(route_length[r]):
                    if routes[r * 7 + at] == pair_i[p]: ri = r; pi = at
                    if routes[r * 7 + at] == pair_j[p]: rj = r; pj = at
        if ri == rj or ri < 0 or rj < 0: continue
        if ((pi != 0 and pi != route_length[ri] - 1) or
                (pj != 0 and pj != route_length[rj] - 1) or load[ri] + load[rj] > cap): continue
        if pi == 0:
            var left = 0; var right = route_length[ri] - 1
            while left < right:
                let t = routes[ri * 7 + left]
                routes[ri * 7 + left] = routes[ri * 7 + right]
                routes[ri * 7 + right] = t
                left += 1; right -= 1
        if pj == route_length[rj] - 1:
            var left = 0; var right = route_length[rj] - 1
            while left < right:
                let t = routes[rj * 7 + left]
                routes[rj * 7 + left] = routes[rj * 7 + right]
                routes[rj * 7 + right] = t
                left += 1; right -= 1
        let old_length = route_length[ri]
        for at in range(route_length[rj]): routes[ri * 7 + old_length + at] = routes[rj * 7 + at]
        route_length[ri] += route_length[rj]
        load[ri] += load[rj]
        active[rj] = False
        route_length[rj] = 0
        load[rj] = 0

    var final_routes = InlineArray[Int, 49](fill=0)
    var final_length = InlineArray[Int, 7](fill=0)
    var count = 0
    for r in range(n):
        if active[r]:
            var reverse_first = False
            for at in range(route_length[r]):
                let a = routes[r * 7 + at]
                let b = routes[r * 7 + route_length[r] - 1 - at]
                if a != b:
                    reverse_first = a > b
                    break
            if reverse_first:
                var left = 0; var right = route_length[r] - 1
                while left < right:
                    let t = routes[r * 7 + left]
                    routes[r * 7 + left] = routes[r * 7 + right]
                    routes[r * 7 + right] = t
                    left += 1; right -= 1
            for at in range(route_length[r]): final_routes[count * 7 + at] = routes[r * 7 + at]
            final_length[count] = route_length[r]
            count += 1
    for i in range(count):
        for j in range(i + 1, count):
            var comparison = 0
            let shared = min(final_length[i], final_length[j])
            for at in range(shared):
                let a = final_routes[i * 7 + at]
                let b = final_routes[j * 7 + at]
                if a != b:
                    comparison = if a < b: -1 else: 1
                    break
            if comparison == 0:
                if final_length[i] < final_length[j]:
                    comparison = -1
                elif final_length[i] > final_length[j]:
                    comparison = 1
            if comparison > 0:
                for k in range(7):
                    let t = final_routes[i * 7 + k]
                    final_routes[i * 7 + k] = final_routes[j * 7 + k]
                    final_routes[j * 7 + k] = t
                let t = final_length[i]; final_length[i] = final_length[j]; final_length[j] = t

    var words = InlineArray[Int64, 15](fill=0)
    var word_count = 0
    words[word_count] = Int64(count); word_count += 1
    for r in range(count):
        words[word_count] = Int64(final_length[r]); word_count += 1
        for at in range(final_length[r]):
            words[word_count] = Int64(final_routes[r * 7 + at]); word_count += 1
    let bytes = word_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2
    for i in range(word_count):
        var bits = UInt64(words[i])
        for b in range(8):
            output[i * 8 + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
