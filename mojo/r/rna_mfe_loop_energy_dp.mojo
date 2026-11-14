from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn rna_pair(a: Int, b: Int) -> Int:
    if a == 0 and b == 3: return 0
    if a == 3 and b == 0: return 1
    if a == 1 and b == 2: return 2
    if a == 2 and b == 1: return 3
    if a == 2 and b == 3: return 4
    if a == 3 and b == 2: return 5
    return -1

fn rna_lex(a: UInt64, b: UInt64, count: Int) -> Bool:
    var i = 0; var j = 0
    while True:
        while i < count and ((a >> i) & 1) == 0: i += 1
        while j < count and ((b >> j) & 1) == 0: j += 1
        if i == count or j == count: return i == count and j < count
        if i != j: return i < j
        i += 1; j += 1

@export("rna_mfe_loop_energy_dp")
fn rna_mfe_loop_energy_dp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 239 or length > 247: return -1
    let nv = input[0]
    if nv < 4 or nv > 12 or length != c_size_t(235+Int(nv)): return -1
    let n = Int(nv)
    var bases = List[Int](capacity=n)
    for i in range(n):
        if input[1+i] < 0 or input[1+i] > 3: return -1
        bases.append(Int(input[1+i]))
    var costs = List[Int64](capacity=234)
    for i in range(234):
        let value = input[1+n+i]
        if value < -1000 or value > 1000: return -1
        costs.append(value)
    var kinds = List[Int](length=n*n, fill=-1)
    var ids = List[Int](length=n*n, fill=-1)
    var pair_i = List[Int](capacity=36); var pair_j = List[Int](capacity=36)
    for i in range(n):
        for j in range(i+4,n):
            let kind = rna_pair(bases[i],bases[j])
            if kind >= 0:
                kinds[i*n+j] = kind; ids[i*n+j] = len(pair_i)
                pair_i.append(i); pair_j.append(j)
    let infinity = Int64(1) << 60
    var energy = List[Int64](length=n*n, fill=infinity)
    var masks = List[UInt64](length=n*n, fill=0)
    for span in range(4,n):
        for i in range(n-span):
            let j = i+span; let kind = kinds[i*n+j]
            if kind < 0: continue
            let outer = UInt64(1) << ids[i*n+j]
            var best = costs[kind*39+(span-1)*3]
            var best_mask = outer
            for a in range(i+1,j):
                for b in range(a+4,j):
                    if ids[a*n+b] < 0 or energy[a*n+b] == infinity: continue
                    let unpaired = a-i-1+j-b-1
                    let candidate = costs[kind*39+unpaired*3+1]+energy[a*n+b]
                    let mask = outer | masks[a*n+b]
                    if candidate < best or (candidate == best and rna_lex(mask,best_mask,len(pair_i))): best = candidate; best_mask = mask
                    for c in range(b+1,j):
                        for d in range(c+4,j):
                            if ids[c*n+d] < 0 or energy[c*n+d] == infinity: continue
                            let u = a-i-1+c-b-1+j-d-1
                            let value = costs[kind*39+u*3+2]+energy[a*n+b]+energy[c*n+d]
                            let combined = outer | masks[a*n+b] | masks[c*n+d]
                            if value < best or (value == best and rna_lex(combined,best_mask,len(pair_i))): best = value; best_mask = combined
            energy[i*n+j] = best; masks[i*n+j] = best_mask
    var prefix = List[Int64](length=n, fill=0)
    var prefix_mask = List[UInt64](length=n, fill=0)
    for j in range(n):
        var best = Int64(0); var best_mask = UInt64(0)
        if j > 0: best = prefix[j-1]; best_mask = prefix_mask[j-1]
        for i in range(j+1):
            if j-i < 4 or ids[i*n+j] < 0 or energy[i*n+j] == infinity: continue
            var value = energy[i*n+j]; var mask = masks[i*n+j]
            if i > 0: value += prefix[i-1]; mask |= prefix_mask[i-1]
            if value < best or (value == best and rna_lex(mask,best_mask,len(pair_i))): best = value; best_mask = mask
        prefix[j] = best; prefix_mask[j] = best_mask
    var fields = List[Int64](capacity=14)
    fields.append(prefix[n-1]); fields.append(0)
    var count = Int64(0)
    for i in range(len(pair_i)):
        if ((prefix_mask[n-1] >> i) & 1) != 0:
            fields.append(Int64(pair_i[i])); fields.append(Int64(pair_j[i])); count += 1
    fields[1] = count
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for j in range(8): output[8*i+j] = UInt8((fields[i] >> (8*j)) & 255)
    return Int64(bytes)
