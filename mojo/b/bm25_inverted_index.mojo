from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("bm25_inverted_index")
fn bm25_inverted_index(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 2114: return -2
    let nval = input[0]
    if nval < 0 or nval > 32: return -2
    let n = Int(nval); let query = input[Int(length) - 1]
    if query < 1 or query > 255: return -2
    var ids = List[Int](capacity=32); var tf = List[Int](capacity=32); var dl = List[Int](capacity=32)
    var seen_ids = List[Bool](capacity=256); for _ in range(256): seen_ids.append(False)
    for _ in range(32): ids.append(0); tf.append(0); dl.append(0)
    var offset = 1; var total_terms = 0
    for d in range(n):
        if offset + 2 > Int(length) - 1: return -2
        let id = input[offset]; let count = input[offset + 1]; offset += 2
        if id < 0 or id > 255 or count < 0 or count > 64 or offset + Int(count) > Int(length) - 1: return -2
        if seen_ids[Int(id)]: return -2
        seen_ids[Int(id)] = True; ids[d] = Int(id); dl[d] = Int(count); total_terms += Int(count)
        for _ in range(Int(count)):
            let term = input[offset]; offset += 1
            if term < 1 or term > 255: return -2
            if term == query: tf[d] += 1
    if offset != Int(length) - 1: return -2
    var result_ids = List[Int](capacity=32); var result_tf = List[Int](capacity=32); var result_den = List[Int](capacity=32)
    var result_count = 0
    for d in range(n):
        if tf[d] == 0: continue
        let den = 8 * total_terms * tf[d] + 3 * total_terms + 9 * n * dl[d]
        var pos = result_count
        while pos > 0:
            let prev = pos - 1
            let lhs = tf[d] * result_den[prev]; let rhs = result_tf[prev] * den
            if lhs < rhs or (lhs == rhs and ids[d] > result_ids[prev]): break
            pos -= 1
        if pos == result_count: result_ids.append(ids[d]); result_tf.append(tf[d]); result_den.append(den)
        else:
            result_ids.append(0); result_tf.append(0); result_den.append(0)
            var j = result_count
            while j > pos:
                result_ids[j] = result_ids[j - 1]; result_tf[j] = result_tf[j - 1]; result_den[j] = result_den[j - 1]
                j -= 1
            result_ids[pos] = ids[d]; result_tf[pos] = tf[d]; result_den[pos] = den
        result_count += 1
    if result_count > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(result_count)): return -2
    for i in range(result_count): output[i] = UInt8(result_ids[i])
    return Int64(result_count)
