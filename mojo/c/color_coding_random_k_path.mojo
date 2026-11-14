from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("color_coding_random_k_path")
fn color_coding_random_k_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 232: return -1
    let nv = input[0]
    let mv = input[1]
    let kv = input[2]
    let tv = input[3]
    if nv < 1 or nv > 12 or mv < 0 or mv > 66 or kv < 1 or kv > 6 or kv > nv or tv < 1 or tv > 8: return -1
    let n = Int(nv)
    let m = Int(mv)
    let k = Int(kv)
    let trials = Int(tv)
    let color_start = 4+2*m
    if length != c_size_t(color_start+trials*n): return -1
    var adjacency = List[Bool](capacity=144)
    for _ in range(144): adjacency.append(False)
    for edge in range(m):
        let uv = input[4+2*edge]
        let vv = input[5+2*edge]
        if uv < 0 or uv >= nv or vv < 0 or vv >= nv or uv == vv: return -1
        let u = Int(uv)
        let v = Int(vv)
        if adjacency[12*u+v]: return -1
        adjacency[12*u+v] = True
        adjacency[12*v+u] = True
    for i in range(trials*n):
        if input[color_start+i] < 0 or input[color_start+i] >= kv: return -1
    let full = (1 << k)-1
    var best = List[Int](capacity=6)
    for _ in range(6): best.append(0)
    var winning_trial = 0
    for trial in range(trials):
        var reach = List[Bool](capacity=768)
        var paths = List[Int](capacity=4608)
        for _ in range(768): reach.append(False)
        for _ in range(4608): paths.append(-1)
        for v in range(n):
            let mask = 1 << Int(input[color_start+trial*n+v])
            reach[12*mask+v] = True
            paths[(12*mask+v)*6] = v
        for mask in range(1, full+1):
            var bits = mask
            var plen = 0
            while bits != 0:
                plen += bits & 1
                bits = bits >> 1
            for v in range(n):
                let source = 12*mask+v
                if not reach[source] or mask == full: continue
                for u in range(n):
                    let bit = 1 << Int(input[color_start+trial*n+u])
                    if not adjacency[12*v+u] or mask & bit != 0: continue
                    let dest = 12*(mask|bit)+u
                    var replace = not reach[dest]
                    if not replace:
                        for i in range(plen+1):
                            var value = u
                            if i < plen: value = paths[6*source+i]
                            if value < paths[6*dest+i]:
                                replace = True
                                break
                            if value > paths[6*dest+i]: break
                    if replace:
                        reach[dest] = True
                        for i in range(plen): paths[6*dest+i] = paths[6*source+i]
                        paths[6*dest+plen] = u
        var has_winner = False
        for v in range(n):
            let cell = 12*full+v
            if not reach[cell]: continue
            var replace = not has_winner
            if not replace:
                for i in range(k):
                    if paths[6*cell+i] < best[i]:
                        replace = True
                        break
                    if paths[6*cell+i] > best[i]: break
            if replace:
                has_winner = True
                for i in range(k): best[i] = paths[6*cell+i]
        if has_winner:
            winning_trial = trial+1
            break
    var bytes = 16
    if winning_trial != 0: bytes = 8*(k+2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    if winning_trial == 0:
        put_word(output, 0, 0)
        put_word(output, 8, 0)
    else:
        put_word(output, 0, 1)
        put_word(output, 8, Int64(winning_trial))
        for i in range(k): put_word(output, 8*(i+2), Int64(best[i]))
    return Int64(bytes)
