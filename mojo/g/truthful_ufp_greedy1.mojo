# Clean-room bounded Greedy-1 routing profile; see package RIGHTS.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import pow
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("truthful_ufp_greedy1")
fn truthful_ufp_greedy1(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 75: return -1
    if input[0] < 2 or input[0] > 8 or input[1] < 1 or input[1] > 16 or input[2] < 1 or input[2] > 8: return -1
    let n = Int(input[0]); let m = Int(input[1]); let k = Int(input[2])
    if length != c_size_t(3+3*m+3*k): return -1
    var eu = InlineArray[Int, 16](fill=0); var ev = InlineArray[Int, 16](fill=0)
    var caps = InlineArray[Int, 16](fill=0); var price = InlineArray[Float64, 16](fill=0.0)
    var minimum = 9; var previous_u: Int64 = -1; var previous_v: Int64 = -1
    for e in range(m):
        let u = input[3+3*e]; let v = input[4+3*e]; let b = input[5+3*e]
        if u < 0 or v <= u or v >= Int64(n) or b < 2 or b > 8 or (e > 0 and (u < previous_u or (u == previous_u and v <= previous_v))): return -1
        eu[e] = Int(u); ev[e] = Int(v); caps[e] = Int(b); price[e] = 1.0/Float64(b)
        if Int(b) < minimum: minimum = Int(b)
        previous_u = u; previous_v = v
    var sources = InlineArray[Int, 8](fill=0); var targets = InlineArray[Int, 8](fill=0)
    var bids = InlineArray[Int, 8](fill=0)
    for i in range(k):
        let s = input[3+3*m+3*i]; let t = input[4+3*m+3*i]; let bid = input[5+3*m+3*i]
        if s < 0 or s >= Int64(n) or t < 0 or t >= Int64(n) or s == t or bid < 1 or bid > 100: return -1
        sources[i] = Int(s); targets[i] = Int(t); bids[i] = Int(bid)
    let threshold = pow(2.718281828459045, Float64(minimum-1))*Float64(m)
    var live = InlineArray[Bool, 8](fill=True)
    var selected = InlineArray[Int, 8](fill=0); var path_lengths = InlineArray[Int, 8](fill=0)
    var paths = InlineArray[Int, 64](fill=0)
    var count = 0
    while count < k:
        var best = -1; var best_score = -1.0
        var route_lengths = InlineArray[Int, 8](fill=0); var routes = InlineArray[Int, 64](fill=0)
        for commodity in range(k):
            if not live[commodity]: continue
            var distance = InlineArray[Float64, 8](fill=1.0e300)
            var parent = InlineArray[Int, 8](fill=-1); var visited = InlineArray[Bool, 8](fill=False)
            distance[sources[commodity]] = 0.0
            for _ in range(n):
                var u = -1
                for v in range(n):
                    if not visited[v] and (u < 0 or distance[v] < distance[u] or (distance[v] == distance[u] and v < u)): u = v
                if u < 0 or distance[u] >= 1.0e299: break
                visited[u] = True
                for e in range(m):
                    var v = -1
                    if eu[e] == u: v = ev[e]
                    elif ev[e] == u: v = eu[e]
                    if v >= 0 and not visited[v]:
                        let candidate = distance[u]+price[e]
                        if candidate < distance[v] or (candidate == distance[v] and (parent[v] < 0 or u < parent[v])):
                            distance[v] = candidate; parent[v] = u
            if distance[targets[commodity]] >= 1.0e299: return -1
            var reverse = InlineArray[Int, 8](fill=0)
            var path_len = 0; var vertex = targets[commodity]
            while vertex != sources[commodity] and path_len < n:
                reverse[path_len] = vertex; path_len += 1
                if parent[vertex] < 0: return -1
                vertex = parent[vertex]
            if vertex != sources[commodity] or path_len >= n: return -1
            reverse[path_len] = vertex; path_len += 1
            route_lengths[commodity] = path_len
            for i in range(path_len): routes[commodity*8+i] = reverse[path_len-1-i]
            let score = Float64(bids[commodity])/distance[targets[commodity]]
            if best < 0 or score > best_score: best = commodity; best_score = score
        if best < 0: break
        live[best] = False; selected[count] = best; path_lengths[count] = route_lengths[best]
        for i in range(path_lengths[count]): paths[count*8+i] = routes[best*8+i]
        count += 1
        for i in range(path_lengths[count-1]-1):
            let u = paths[(count-1)*8+i]; let v = paths[(count-1)*8+i+1]
            for e in range(m):
                if (eu[e] == u and ev[e] == v) or (eu[e] == v and ev[e] == u):
                    price[e] *= pow(threshold, 1.0/Float64(caps[e]-1))
        var dual = 0.0
        for e in range(m): dual += Float64(caps[e])*price[e]
        if dual >= threshold: break
    var words = InlineArray[Int64, 81](fill=0)
    words[0] = Int64(count)
    var used = 1
    for i in range(count):
        words[used] = Int64(selected[i]); words[used+1] = Int64(path_lengths[i]); used += 2
        for j in range(path_lengths[i]): words[used] = Int64(paths[i*8+j]); used += 1
    let bytes = 8*used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(used):
        let bits = UInt64(words[i])
        for b in range(8): output[8*i+b] = UInt8((bits >> (8*b)) & 255)
    return Int64(bytes)
