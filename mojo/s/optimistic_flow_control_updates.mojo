from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FLOW_SCALE = 46656

fn flow_choose(mode: Int, step: Int, n: Int, links: Int, cap: InlineArray[Int64, 4],
               paths: InlineArray[Bool, 12], rates: InlineArray[Int64, 3]) -> Int:
    if mode == 0: return step % n
    if mode == 1:
        var best = 0
        for s in range(1, n):
            if rates[s] < rates[best]: best = s
        return best
    if mode == 2:
        for s in range(n):
            var local = True
            for j in range(n):
                if j == s: continue
                var shares = False
                for e in range(links):
                    if paths[4 * s + e] and paths[4 * j + e]: shares = True
                if shares and (rates[j] < rates[s] or (rates[j] == rates[s] and j < s)): local = False
            if local: return s
        return 0
    var selected = links
    var best_load: Int64 = 0
    for e in range(links):
        var load: Int64 = 0
        var active = False
        for s in range(n):
            if paths[4 * s + e]:
                load += rates[s]
                active = True
        if active:
            if selected == links:
                selected = e
                best_load = load
            elif load * cap[selected] > best_load * cap[e]:
                selected = e
                best_load = load
    for s in range(n):
        if paths[4 * s + selected]: return s
    return 0

fn flow_update(session: Int, n: Int, links: Int, cap: InlineArray[Int64, 4],
               paths: InlineArray[Bool, 12], inout rates: InlineArray[Int64, 3]) -> Bool:
    var best: Int64 = 9223372036854775807
    var bottleneck = links
    for e in range(links):
        if not paths[4 * session + e]: continue
        var fixed: Int64 = 0
        var active: Int64 = 1
        for j in range(n):
            if j != session and paths[4 * j + e]:
                if rates[j] <= rates[session]: fixed += rates[j]
                else: active += 1
        var level = rates[session]
        var candidate = level
        for _ in range(n):
            let numerator = cap[e] * FLOW_SCALE - fixed
            if numerator < 0 or numerator % active != 0: return False
            candidate = numerator // active
            if candidate < level: return False
            var next: Int64 = 9223372036854775807
            for j in range(n):
                if j != session and paths[4 * j + e] and rates[j] > level and rates[j] < next: next = rates[j]
            if next == 9223372036854775807 or candidate <= next: break
            var saturated: Int64 = 0
            for j in range(n):
                if j != session and paths[4 * j + e] and rates[j] == next: saturated += 1
            fixed += saturated * next
            active -= saturated
            level = next
        if candidate < best:
            best = candidate
            bottleneck = e
    if bottleneck == links: return False
    rates[session] = best
    for j in range(n):
        if j != session and paths[4 * j + bottleneck] and rates[j] > best: rates[j] = best
    return True

@export("optimistic_flow_control_updates")
fn optimistic_flow_control_updates(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 20: return -1
    if input[0] < 2 or input[0] > 3 or input[1] < 1 or input[1] > 4: return -1
    if input[2] < 0 or input[2] > 3 or input[3] < 1 or input[3] > 6: return -1
    let n = Int(input[0])
    let links = Int(input[1])
    if Int(length) != 4 + links + n * links: return -1
    var cap = InlineArray[Int64, 4](fill=0)
    var paths = InlineArray[Bool, 12](fill=False)
    var rates = InlineArray[Int64, 3](fill=0)
    for e in range(links):
        cap[e] = input[4 + e]
        if cap[e] < 1 or cap[e] > 16: return -1
    for s in range(n):
        var used = False
        for e in range(links):
            let value = input[4 + links + s * links + e]
            if value != 0 and value != 1: return -1
            paths[4 * s + e] = value == 1
            if value == 1: used = True
        if not used: return -1
    for step in range(Int(input[3])):
        let session = flow_choose(Int(input[2]), step, n, links, cap, paths, rates)
        if not flow_update(session, n, links, cap, paths, rates): return -1
    let bytes = 16 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for s in range(n):
        var a = rates[s]
        var b: Int64 = FLOW_SCALE
        while b != 0:
            let remainder = a % b
            a = b
            b = remainder
        for part in range(2):
            let value = if part == 0: rates[s] // a else: Int64(FLOW_SCALE) // a
            var bits = UInt64(value)
            for byte in range(8):
                output[16 * s + 8 * part + byte] = UInt8(bits & 255)
                bits >>= 8
    return Int64(bytes)
