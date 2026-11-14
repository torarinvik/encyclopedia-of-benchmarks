from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn routing_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("packet_routing_work_conserving_schedule")
fn packet_routing_work_conserving_schedule(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 99: return -1
    let nv = input[0]
    let mv = input[1]
    let pv = input[2]
    if nv < 2 or nv > 8 or mv < 1 or mv > 12 or pv < 1 or pv > 8: return -1
    let n = Int(nv)
    let m = Int(mv)
    let p = Int(pv)
    var cursor = 3
    if cursor + 2 * m > Int(length): return -1
    var u = InlineArray[Int, 12](fill=0)
    var v = InlineArray[Int, 12](fill=0)
    var seen_edges = InlineArray[Bool, 64](fill=False)
    for edge in range(m):
        let a = input[cursor]
        let b = input[cursor + 1]
        cursor += 2
        if a < 0 or a >= nv or b < 0 or b >= nv or a == b: return -1
        u[edge] = Int(a)
        v[edge] = Int(b)
        let index = min(Int(a), Int(b)) * 8 + max(Int(a), Int(b))
        if seen_edges[index]: return -1
        seen_edges[index] = True
    var lengths = InlineArray[Int, 8](fill=0)
    var paths = InlineArray[Int, 64](fill=0)
    for packet in range(p):
        if cursor + 2 > Int(length): return -1
        let start = input[cursor]
        let steps = input[cursor + 1]
        cursor += 2
        if start < 0 or start >= nv or steps < 1 or steps >= nv or cursor + Int(steps) > Int(length): return -1
        lengths[packet] = Int(steps)
        var current = Int(start)
        var visited = InlineArray[Bool, 8](fill=False)
        visited[current] = True
        for j in range(Int(steps)):
            let raw = input[cursor]
            cursor += 1
            if raw < 0 or raw >= mv: return -1
            let edge = Int(raw)
            paths[8 * packet + j] = edge
            if u[edge] == current: current = v[edge]
            elif v[edge] == current: current = u[edge]
            else: return -1
            if visited[current]: return -1
            visited[current] = True
    if cursor != Int(length): return -1
    var positions = InlineArray[Int, 8](fill=0)
    var records = InlineArray[Int64, 168](fill=0)
    var count = 0
    var time = 0
    while True:
        var active = False
        var chosen = InlineArray[Int, 12](fill=-1)
        for packet in range(p):
            if positions[packet] < lengths[packet]:
                active = True
                let edge = paths[8 * packet + positions[packet]]
                if chosen[edge] < 0: chosen[edge] = packet
        if not active: break
        for edge in range(m):
            let packet = chosen[edge]
            if packet >= 0:
                if count >= 56: return -1
                records[3 * count] = Int64(time)
                records[3 * count + 1] = Int64(edge)
                records[3 * count + 2] = Int64(packet)
                count += 1
                positions[packet] += 1
        time += 1
        if time > 64: return -1
    let bytes = 8 * (2 + 3 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    routing_store(output, 0, Int64(time))
    routing_store(output, 1, Int64(count))
    for i in range(3 * count): routing_store(output, 2 + i, records[i])
    return Int64(bytes)
