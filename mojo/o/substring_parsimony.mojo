# Finite-metric tree parsimony and lexicographic optimal-label enumeration.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("substring_parsimony")
fn substring_parsimony(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 10 or length > 26: return -1
    let qv = input[0]
    let threshold = input[1]
    if qv < 1 or qv > 4 or threshold < 0 or threshold > 36 or length != c_size_t(9+qv*qv): return -1
    let q = Int(qv)
    var children = List[Int](capacity=4)
    for i in range(4):
        let child = input[2+i]
        if child < 1 or child > 4: return -1
        children.append(Int(child))
    if children[0] == children[1] or children[2] == children[3]: return -1
    var root_leaf = -1
    if children[0] == 1: root_leaf = children[1]
    elif children[1] == 1: root_leaf = children[0]
    if root_leaf < 2 or root_leaf > 4 or children[2] < 2 or children[3] < 2 or children[2] == root_leaf or children[3] == root_leaf: return -1
    var masks = List[Int](capacity=3)
    for i in range(3):
        let mask = input[6+i]
        if mask <= 0 or mask >= Int64(1 << q): return -1
        masks.append(Int(mask))
    var distance = List[Int64](capacity=q*q)
    for i in range(q):
        for j in range(q):
            let value = input[9+i*q+j]
            if value < 0 or value > 9 or (i == j and value != 0) or (i != j and value == 0) or value != input[9+j*q+i]: return -1
            distance.append(value)
    for i in range(q):
        for j in range(q):
            for k in range(q):
                if distance[i*q+k] > distance[i*q+j]+distance[j*q+k]: return -1
    var dp = List[Int64](capacity=5*q)
    for _ in range(5*q): dp.append(1000000)
    for leaf in range(2,5):
        for state in range(q):
            if (masks[leaf-2] & (1 << state)) != 0: dp[leaf*q+state] = 0
    var node = 2
    while node > 0:
        node -= 1
        for state in range(q):
            var total = Int64(0)
            for slot in range(2):
                let child = children[2*node+slot]
                var best = Int64(1000000)
                for other in range(q):
                    let candidate = dp[child*q+other]+distance[state*q+other]
                    if candidate < best: best = candidate
                total += best
            dp[node*q+state] = total
    var optimum = Int64(1000000)
    for state in range(q):
        if dp[state] < optimum: optimum = dp[state]
    var fields = List[Int64](capacity=5122)
    fields.append(optimum); fields.append(0)
    if optimum <= threshold:
        let count = q*q*q*q*q
        var labels = List[Int](capacity=5)
        for _ in range(5): labels.append(0)
        for encoded in range(count):
            var remaining = encoded
            var digit = 5
            while digit > 0:
                digit -= 1
                labels[digit] = remaining % q
                remaining //= q
            var allowed = True
            for leaf in range(2,5):
                if (masks[leaf-2] & (1 << labels[leaf])) == 0: allowed = False
            if not allowed: continue
            var score = Int64(0)
            for parent in range(2):
                for slot in range(2): score += distance[labels[parent]*q+labels[children[2*parent+slot]]]
            if score == optimum:
                for vertex in range(5): fields.append(Int64(labels[vertex]))
                fields[1] += 1
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
