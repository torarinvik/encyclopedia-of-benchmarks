from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn drm_combine(av: Int, ac: Int, bv: Int, bc: Int) -> (Int, Int):
    if ac == 0: return (bv, bc)
    if bc == 0: return (av, ac)
    if av == bv: return (av, ac+bc)
    if ac >= bc: return (av, ac-bc)
    return (bv, bc-ac)

fn drm_slot(value: Int, mut names: InlineArray[Int, 128], mut size: Int) -> Int:
    for i in range(size):
        if names[i] == value: return i
    let result = size
    names[size] = value
    size += 1
    return result

fn drm_prefix(pos: Int) -> UInt64:
    if pos == 64: return ~UInt64(0)
    return (UInt64(1) << pos)-1

@export("dynamic_range_majority")
fn dynamic_range_majority(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1
    if input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64: return -1
    let n = Int(input[0]); let q = Int(input[1])
    if length != c_size_t(2+n+3*q): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 1000000000: return -1
    var queries = 0
    for i in range(q):
        let b = 2+n+3*i
        if input[b] == 0:
            if input[b+1] < 0 or input[b+1] >= n or input[b+2] < 0 or input[b+2] > 1000000000: return -1
        elif input[b] == 1:
            if input[b+1] < 0 or input[b+1] >= input[b+2] or input[b+2] > n: return -1
            queries += 1
        else: return -1
    if queries == 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*queries): return -2
    var values = InlineArray[Int, 128](fill=0)
    var counts = InlineArray[Int, 128](fill=0)
    var names = InlineArray[Int, 128](fill=0)
    var masks = InlineArray[UInt64, 128](fill=0)
    var data = InlineArray[Int, 64](fill=0)
    var distinct = 0
    for i in range(n):
        data[i] = Int(input[2+i]); values[64+i] = data[i]; counts[64+i] = 1
        let slot = drm_slot(data[i], names, distinct)
        masks[slot] |= UInt64(1) << i
    var node = 63
    while node > 0:
        let (v,c) = drm_combine(values[2*node],counts[2*node],values[2*node+1],counts[2*node+1])
        values[node] = v; counts[node] = c; node -= 1
    var written = 0
    for i in range(q):
        let b = 2+n+3*i
        if input[b] == 0:
            let p = Int(input[b+1]); let value = Int(input[b+2])
            let old = drm_slot(data[p], names, distinct)
            let new_slot = drm_slot(value, names, distinct)
            masks[old] &= ~(UInt64(1) << p); masks[new_slot] |= UInt64(1) << p
            data[p] = value; node = 64+p; values[node] = value; counts[node] = 1
            while node > 1:
                node //= 2
                let (v,c) = drm_combine(values[2*node],counts[2*node],values[2*node+1],counts[2*node+1])
                values[node] = v; counts[node] = c
        else:
            let lo = Int(input[b+1]); let hi = Int(input[b+2])
            var l = 64+lo; var r = 64+hi
            var av = 0; var ac = 0; var bv = 0; var bc = 0
            while l < r:
                if (l & 1) != 0:
                    let (v,c) = drm_combine(av,ac,values[l],counts[l])
                    av = v; ac = c; l += 1
                if (r & 1) != 0:
                    r -= 1
                    let (v,c) = drm_combine(values[r],counts[r],bv,bc)
                    bv = v; bc = c
                l //= 2; r //= 2
            let (candidate,balance) = drm_combine(av,ac,bv,bc)
            var answer = -1
            if balance > 0:
                let slot = drm_slot(candidate, names, distinct)
                var bits = masks[slot] & (drm_prefix(hi) ^ drm_prefix(lo))
                var occurrences = 0
                while bits != 0:
                    bits &= bits-1; occurrences += 1
                if 2*occurrences > hi-lo: answer = candidate
            for byte in range(8):
                if answer < 0: output[8*written+byte] = 255
                else: output[8*written+byte] = UInt8((answer >> (8*byte)) & 255)
            written += 1
    return Int64(8*written)
