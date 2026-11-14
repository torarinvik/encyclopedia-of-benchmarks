from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("color_coding_k_path")
fn color_coding_k_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 147: return -1
    let nv = input[0]
    let mv = input[1]
    let kv = input[2]
    if nv < 1 or nv > 12 or mv < 0 or mv > 66 or kv < 1 or kv > 6 or kv > nv: return -1
    let n = Int(nv)
    let m = Int(mv)
    let k = Int(kv)
    let split = 3+n
    if length != c_size_t(split+2*m): return -1
    var colors = List[Int](capacity=12)
    var adjacency = List[Bool](capacity=144)
    var dp = List[Bool](capacity=768)
    for _ in range(12): colors.append(0)
    for _ in range(144): adjacency.append(False)
    for _ in range(768): dp.append(False)
    for v in range(n):
        let color = input[3+v]
        if color < 0 or color >= kv: return -1
        colors[v] = Int(color)
    for edge in range(m):
        let uv = input[split+2*edge]
        let vv = input[split+2*edge+1]
        if uv < 0 or uv >= nv or vv < 0 or vv >= nv or uv == vv: return -1
        let u = Int(uv)
        let v = Int(vv)
        if adjacency[12*u+v]: return -1
        adjacency[12*u+v] = True
        adjacency[12*v+u] = True
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for v in range(n): dp[12*(1 << colors[v])+v] = True
    let full = (1 << k)-1
    var found = False
    for mask in range(1, full+1):
        for v in range(n):
            if not dp[12*mask+v]: continue
            if mask == full:
                found = True
                break
            for u in range(n):
                let bit = 1 << colors[u]
                if adjacency[12*v+u] and mask & bit == 0:
                    dp[12*(mask|bit)+u] = True
        if found: break
    output[0] = UInt8(1) if found else UInt8(0)
    for i in range(1, 8): output[i] = UInt8(0)
    return 8
