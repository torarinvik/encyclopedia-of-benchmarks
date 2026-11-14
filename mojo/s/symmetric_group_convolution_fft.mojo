# Uncompiled Mojo ABI draft. Recoverable allocation failures remain unresolved.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime SG_PRIME = Int64(998244353)
comptime SG_BASIS = 603

fn sg_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var value = Int64(1)
    while exponent > 0:
        if (exponent & 1) != 0: value = (value*base) % SG_PRIME
        base = (base*base) % SG_PRIME
        exponent >>= 1
    return value

# Slot is degree*30+shape. Basis cells use (slot*603+tableau)*9+label.
fn sg_enumerate(n: Int, next: Int, mut shape: List[Int], mut tableau: List[Int],
                mut level_counts: List[Int], mut shapes: List[Int],
                mut counts: List[Int], mut basis: List[Int]) -> Bool:
    if next == n:
        var index = 0
        while index < level_counts[n]:
            var matches = True
            for i in range(9):
                if shapes[(n*30+index)*9+i] != shape[i]: matches = False
            if matches: break
            index += 1
        if index == level_counts[n]:
            if index == 30: return False
            for i in range(9): shapes[(n*30+index)*9+i] = shape[i]
            level_counts[n] += 1
        let slot = n*30+index
        if counts[slot] >= SG_BASIS: return False
        for i in range(n): basis[(slot*SG_BASIS+counts[slot])*9+i] = tableau[i]
        counts[slot] += 1
        return True
    var row = 0
    while row < n:
        var allowed = True
        if row > 0 and shape[row] >= shape[row-1]: allowed = False
        if allowed:
            let column = shape[row]
            tableau[next] = row*9+column
            shape[row] = column+1
            let ok = sg_enumerate(n,next+1,shape,tableau,level_counts,shapes,counts,basis)
            shape[row] = column
            if not ok: return False
            if column == 0: break
        row += 1
    return True

fn sg_basis_less(basis: List[Int], slot: Int, left: Int, right: Int, n: Int) -> Bool:
    var label = n
    while label > 0:
        label -= 1
        let a = basis[(slot*SG_BASIS+left)*9+label]
        let b = basis[(slot*SG_BASIS+right)*9+label]
        if a < b: return True
        if a > b: return False
    return False

# Caller provides disjoint buffers sized 10, 2700, 300, 1628100, 300,
# 2700, 2700, 2700. The last three record child, offset, width respectively.
fn sg_make_tableau_plan(degree: Int, mut level_counts: List[Int], mut shapes: List[Int],
                        mut counts: List[Int], mut basis: List[Int], mut restriction_counts: List[Int],
                        mut children: List[Int], mut offsets: List[Int], mut widths: List[Int]) -> Bool:
    if degree < 1 or degree > 9: return False
    if len(level_counts) < 10 or len(shapes) < 2700 or len(counts) < 300 or len(basis) < 1628100: return False
    if len(restriction_counts) < 300 or len(children) < 2700 or len(offsets) < 2700 or len(widths) < 2700: return False
    for i in range(10): level_counts[i] = 0
    for i in range(300):
        counts[i] = 0
        restriction_counts[i] = 0
    for n in range(1,degree+1):
        var shape = List[Int](length=9, fill=0)
        var tableau = List[Int](length=9, fill=0)
        if not sg_enumerate(n,0,shape,tableau,level_counts,shapes,counts,basis): return False
        for r in range(level_counts[n]):
            let slot = n*30+r
            for i in range(1,counts[slot]):
                var j = i
                while j > 0 and sg_basis_less(basis,slot,j,j-1,n):
                    for label in range(n):
                        let a = (slot*SG_BASIS+j)*9+label
                        let b = (slot*SG_BASIS+j-1)*9+label
                        let value = basis[a]
                        basis[a] = basis[b]
                        basis[b] = value
                    j -= 1
        if n > 1:
            for r in range(level_counts[n]):
                let slot = n*30+r
                var start = 0
                while start < counts[slot]:
                    let corner = basis[(slot*SG_BASIS+start)*9+n-1]
                    var end = start+1
                    while end < counts[slot] and basis[(slot*SG_BASIS+end)*9+n-1] == corner: end += 1
                    let row = corner // 9
                    if row < 0 or row >= 9 or shapes[slot*9+row] == 0: return False
                    var child = 0
                    var found = False
                    while child < level_counts[n-1] and not found:
                        let candidate = (n-1)*30+child
                        var matches = True
                        for label in range(9):
                            var expected = shapes[slot*9+label]
                            if label == row: expected -= 1
                            if shapes[candidate*9+label] != expected: matches = False
                        if matches: found = True
                        else: child += 1
                    if not found: return False
                    let child_slot = (n-1)*30+child
                    if counts[child_slot] != end-start: return False
                    for i in range(end-start):
                        for label in range(n-1):
                            if basis[(slot*SG_BASIS+start+i)*9+label] != basis[(child_slot*SG_BASIS+i)*9+label]: return False
                    let block = restriction_counts[slot]
                    if block >= 9: return False
                    let at = slot*9+block
                    children[at] = child
                    offsets[at] = start
                    widths[at] = end-start
                    restriction_counts[slot] = block+1
                    start = end
    return True

fn sg_compare_target(basis: List[Int], slot: Int, index: Int, target: List[Int], n: Int) -> Int:
    var label = n
    while label > 0:
        label -= 1
        let value = basis[(slot*SG_BASIS+index)*9+label]
        if value < target[label]: return -1
        if value > target[label]: return 1
    return 0

# Generator columns use (slot*8+label)*603+column; partner -1 means no
# off-diagonal entry. All three output lists are disjoint and caller-owned.
fn sg_make_generators(degree: Int, level_counts: List[Int], counts: List[Int], basis: List[Int],
                      mut diagonals: List[Int64], mut partners: List[Int],
                      mut coefficients: List[Int64]) -> Bool:
    if degree < 1 or degree > 9: return False
    if len(level_counts) < 10 or len(counts) < 300 or len(basis) < 1628100: return False
    if len(diagonals) < 1447200 or len(partners) < 1447200 or len(coefficients) < 1447200: return False
    for n in range(1,degree+1):
        if level_counts[n] < 0 or level_counts[n] > 30: return False
        for r in range(level_counts[n]):
            let slot = n*30+r
            let count = counts[slot]
            if count < 1 or count > SG_BASIS: return False
            for label in range(n-1):
                for index in range(count):
                    let first = basis[(slot*SG_BASIS+index)*9+label]
                    let second = basis[(slot*SG_BASIS+index)*9+label+1]
                    let distance = second%9-second//9-first%9+first//9
                    if distance == 0: return False
                    let diagonal = sg_power((Int64(distance)+SG_PRIME)%SG_PRIME,SG_PRIME-2)
                    let at = (slot*8+label)*SG_BASIS+index
                    diagonals[at] = diagonal
                    partners[at] = -1
                    coefficients[at] = 0
                    if distance != 1 and distance != -1:
                        var target = List[Int](length=9, fill=0)
                        for i in range(n): target[i] = basis[(slot*SG_BASIS+index)*9+i]
                        let temp = target[label]
                        target[label] = target[label+1]
                        target[label+1] = temp
                        var low = 0
                        var high = count
                        while low < high:
                            let mid = low+(high-low)//2
                            if sg_compare_target(basis,slot,mid,target,n) < 0: low = mid+1
                            else: high = mid
                        if low == count: return False
                        if sg_compare_target(basis,slot,low,target,n) != 0: return False
                        partners[at] = low
                        if distance > 0: coefficients[at] = 1
                        else: coefficients[at] = (1-diagonal*diagonal%SG_PRIME+SG_PRIME)%SG_PRIME
    return True

fn sg_factorial(n: Int) -> Int:
    var value = 1
    for i in range(2,n+1): value *= i
    return value

fn sg_rank(permutation: List[Int], n: Int) -> Int:
    if n < 1 or n > 9 or len(permutation) < n: return -1
    var rank = 0
    for i in range(n):
        if permutation[i] < 0 or permutation[i] >= n: return -1
        var smaller = 0
        for j in range(i+1,n):
            if permutation[j] == permutation[i]: return -1
            if permutation[j] < permutation[i]: smaller += 1
        rank += smaller*sg_factorial(n-1-i)
    return rank

fn sg_next_permutation(mut values: List[Int], n: Int) -> Bool:
    if n < 2 or n > 9 or len(values) < n: return False
    var pivot = n-1
    while pivot > 0 and values[pivot-1] >= values[pivot]: pivot -= 1
    if pivot == 0: return False
    var successor = n-1
    while values[successor] <= values[pivot-1]: successor -= 1
    let temp = values[pivot-1]
    values[pivot-1] = values[successor]
    values[successor] = temp
    var left = pivot
    var right = n-1
    while left < right:
        let value = values[left]
        values[left] = values[right]
        values[right] = value
        left += 1
        right -= 1
    return True

# Returns an empty list on invariant failure. A valid matrix always has d*d
# elements, and d is positive. The source remains unchanged.
fn sg_apply_generator(slot: Int, label: Int, d: Int, diagonals: List[Int64],
                      partners: List[Int], coefficients: List[Int64],
                      source: List[Int64], transpose: Bool) -> List[Int64]:
    if slot < 0 or slot >= 300 or label < 0 or label >= 8 or d < 1 or d > SG_BASIS:
        return List[Int64]()
    let base = (slot*8+label)*SG_BASIS
    if len(diagonals) < base+d or len(partners) < base+d or len(coefficients) < base+d or len(source) != d*d:
        return List[Int64]()
    var result = List[Int64](length=d*d, fill=0)
    for row in range(d):
        let diagonal = diagonals[base+row]
        let partner = partners[base+row]
        let coefficient = coefficients[base+row]
        if diagonal < 0 or diagonal >= SG_PRIME or partner < -1 or partner >= d or coefficient < 0 or coefficient >= SG_PRIME:
            return List[Int64]()
        for col in range(d):
            if transpose:
                var value = (diagonal*source[row*d+col])%SG_PRIME
                if partner >= 0: value = (value+coefficient*source[partner*d+col])%SG_PRIME
                result[row*d+col] = value
            else:
                let value = source[row*d+col]
                let at = row*d+col
                result[at] = (result[at]+diagonal*value)%SG_PRIME
                if partner >= 0:
                    let target = partner*d+col
                    result[target] = (result[target]+coefficient*value)%SG_PRIME
    return result^

fn sg_block_offset(n: Int, shape: Int, level_counts: List[Int], counts: List[Int]) -> Int:
    if n < 1 or n > 9 or len(level_counts) < 10 or len(counts) < 300: return -1
    if level_counts[n] < 0 or level_counts[n] > 30 or shape < 0 or shape > level_counts[n]: return -1
    var total = 0
    for i in range(shape):
        let dimension = counts[n*30+i]
        if dimension < 1 or dimension > SG_BASIS: return -1
        total += dimension*dimension
        if total > sg_factorial(n): return -1
    return total

# Packed output has exactly n! entries on success; an empty list signals an
# invariant failure. Intermediate lists are scoped to their recursive call.
fn sg_forward(n: Int, input: List[Int64], level_counts: List[Int], counts: List[Int],
              restriction_counts: List[Int], children: List[Int], offsets: List[Int], widths: List[Int],
              diagonals: List[Int64], partners: List[Int], coefficients: List[Int64]) -> List[Int64]:
    if n < 1 or n > 9: return List[Int64]()
    let total = sg_factorial(n)
    if len(input) != total or len(level_counts) < 10 or len(counts) < 300 or len(restriction_counts) < 300:
        return List[Int64]()
    if len(children) < 2700 or len(offsets) < 2700 or len(widths) < 2700: return List[Int64]()
    if level_counts[n] < 1 or level_counts[n] > 30: return List[Int64]()
    if sg_block_offset(n,level_counts[n],level_counts,counts) != total: return List[Int64]()
    var output = List[Int64](length=total, fill=0)
    if n == 1:
        output[0] = input[0]
        return output^
    let child_size = sg_factorial(n-1)
    for image in range(n):
        var restricted = List[Int64](length=child_size, fill=0)
        var h = List[Int](length=9, fill=0)
        var permutation = List[Int](length=9, fill=0)
        for i in range(n-1): h[i] = i
        var index = 0
        var more = True
        while more:
            for i in range(n-1): permutation[i] = h[i]
            permutation[n-1] = n-1
            for i in range(n):
                if permutation[i] == image: permutation[i] = n-1
                elif permutation[i] == n-1: permutation[i] = image
            let rank = sg_rank(permutation,n)
            if rank < 0 or index >= child_size: return List[Int64]()
            restricted[index] = input[rank]
            index += 1
            more = sg_next_permutation(h,n-1)
        if index != child_size: return List[Int64]()
        let child = sg_forward(n-1,restricted,level_counts,counts,restriction_counts,
                               children,offsets,widths,diagonals,partners,coefficients)
        if len(child) != child_size: return List[Int64]()
        for shape in range(level_counts[n]):
            let slot = n*30+shape
            let d = counts[slot]
            if d < 1 or d > SG_BASIS: return List[Int64]()
            let square = d*d
            let block_offset = sg_block_offset(n,shape,level_counts,counts)
            if block_offset < 0 or block_offset+square > total: return List[Int64]()
            if restriction_counts[slot] < 0 or restriction_counts[slot] > 9: return List[Int64]()
            var embedded = List[Int64](length=square, fill=0)
            for k in range(restriction_counts[slot]):
                let at = slot*9+k
                let child_index = children[at]
                let offset = offsets[at]
                let width = widths[at]
                if child_index < 0 or child_index >= level_counts[n-1] or offset < 0 or width < 1:
                    return List[Int64]()
                if offset+width > d or counts[(n-1)*30+child_index] != width: return List[Int64]()
                let child_offset = sg_block_offset(n-1,child_index,level_counts,counts)
                if child_offset < 0 or child_offset+width*width > child_size: return List[Int64]()
                for row in range(width):
                    for col in range(width):
                        embedded[(offset+row)*d+offset+col] = child[child_offset+row*width+col]
            for generator in range(image,n-1):
                var updated = sg_apply_generator(slot,generator,d,diagonals,partners,coefficients,embedded,False)
                if len(updated) != square: return List[Int64]()
                embedded = updated^
            var generator = n-3
            while generator >= image:
                var updated = sg_apply_generator(slot,generator,d,diagonals,partners,coefficients,embedded,False)
                if len(updated) != square: return List[Int64]()
                embedded = updated^
                generator -= 1
            for i in range(square): output[block_offset+i] = (output[block_offset+i]+embedded[i])%SG_PRIME
    return output^

# Empty output denotes an invalid generator graph; a valid diagonal has d > 0.
fn sg_invariant_diagonal(n: Int, slot: Int, d: Int,
                         partners: List[Int], coefficients: List[Int64]) -> List[Int64]:
    if n < 1 or n > 9 or slot < 0 or slot >= 300 or d < 1 or d > SG_BASIS:
        return List[Int64]()
    if len(partners) < 1447200 or len(coefficients) < 1447200: return List[Int64]()
    var weights = List[Int64](length=d, fill=-1)
    var queue = List[Int](length=d, fill=0)
    for start in range(d):
        if weights[start] != -1: continue
        weights[start] = 1
        queue[0] = start
        var head = 0
        var tail = 1
        while head < tail:
            let source = queue[head]
            head += 1
            for label in range(n-1):
                let base = (slot*8+label)*SG_BASIS
                let target = partners[base+source]
                if target < -1 or target >= d: return List[Int64]()
                if target >= 0:
                    let forward = coefficients[base+source]
                    let backward = coefficients[base+target]
                    if partners[base+target] != source: return List[Int64]()
                    if forward < 1 or forward >= SG_PRIME or backward < 1 or backward >= SG_PRIME:
                        return List[Int64]()
                    var candidate = (weights[source]*backward)%SG_PRIME
                    candidate = (candidate*sg_power(forward,SG_PRIME-2))%SG_PRIME
                    if candidate == 0: return List[Int64]()
                    if weights[target] == -1:
                        if tail >= d: return List[Int64]()
                        weights[target] = candidate
                        queue[tail] = target
                        tail += 1
                    elif weights[target] != candidate: return List[Int64]()
    return weights^

fn sg_weight_blocks(n: Int, blocks: List[Int64], level_counts: List[Int], counts: List[Int],
                    partners: List[Int], coefficients: List[Int64]) -> List[Int64]:
    if n < 1 or n > 9 or len(level_counts) < 10 or len(counts) < 300: return List[Int64]()
    if level_counts[n] < 1 or level_counts[n] > 30: return List[Int64]()
    let total = sg_factorial(n)
    if len(blocks) != total or sg_block_offset(n,level_counts[n],level_counts,counts) != total:
        return List[Int64]()
    let inverse_order = sg_power(Int64(total),SG_PRIME-2)
    var weighted = List[Int64](length=total, fill=0)
    for shape in range(level_counts[n]):
        let slot = n*30+shape
        let d = counts[slot]
        if d < 1 or d > SG_BASIS: return List[Int64]()
        let offset = sg_block_offset(n,shape,level_counts,counts)
        if offset < 0 or offset+d*d > total: return List[Int64]()
        let diagonal = sg_invariant_diagonal(n,slot,d,partners,coefficients)
        if len(diagonal) != d: return List[Int64]()
        var inverse_diagonal = List[Int64](length=d, fill=0)
        for i in range(d): inverse_diagonal[i] = sg_power(diagonal[i],SG_PRIME-2)
        for row in range(d):
            for col in range(d):
                let at = offset+row*d+col
                if blocks[at] < 0 or blocks[at] >= SG_PRIME: return List[Int64]()
                var value = (blocks[at]*Int64(d))%SG_PRIME
                value = (value*inverse_order)%SG_PRIME
                value = (value*diagonal[row])%SG_PRIME
                weighted[at] = (value*inverse_diagonal[col])%SG_PRIME
    return weighted^

fn sg_transpose_forward(n: Int, gradients: List[Int64], level_counts: List[Int], counts: List[Int],
                        restriction_counts: List[Int], children: List[Int], offsets: List[Int], widths: List[Int],
                        diagonals: List[Int64], partners: List[Int], coefficients: List[Int64]) -> List[Int64]:
    if n < 1 or n > 9: return List[Int64]()
    let total = sg_factorial(n)
    if len(gradients) != total or len(level_counts) < 10 or len(counts) < 300 or len(restriction_counts) < 300:
        return List[Int64]()
    if len(children) < 2700 or len(offsets) < 2700 or len(widths) < 2700: return List[Int64]()
    if level_counts[n] < 1 or level_counts[n] > 30: return List[Int64]()
    if sg_block_offset(n,level_counts[n],level_counts,counts) != total: return List[Int64]()
    var output = List[Int64](length=total, fill=0)
    if n == 1:
        output[0] = gradients[0]
        return output^
    let child_size = sg_factorial(n-1)
    for image in range(n):
        var child = List[Int64](length=child_size, fill=0)
        for shape in range(level_counts[n]):
            let slot = n*30+shape
            let d = counts[slot]
            if d < 1 or d > SG_BASIS: return List[Int64]()
            let square = d*d
            let block_offset = sg_block_offset(n,shape,level_counts,counts)
            if block_offset < 0 or block_offset+square > total: return List[Int64]()
            if restriction_counts[slot] < 0 or restriction_counts[slot] > 9: return List[Int64]()
            var current = List[Int64](length=square, fill=0)
            for i in range(square): current[i] = gradients[block_offset+i]
            for generator in range(image,n-1):
                var updated = sg_apply_generator(slot,generator,d,diagonals,partners,coefficients,current,True)
                if len(updated) != square: return List[Int64]()
                current = updated^
            var generator = n-3
            while generator >= image:
                var updated = sg_apply_generator(slot,generator,d,diagonals,partners,coefficients,current,True)
                if len(updated) != square: return List[Int64]()
                current = updated^
                generator -= 1
            for k in range(restriction_counts[slot]):
                let at = slot*9+k
                let child_index = children[at]
                let offset = offsets[at]
                let width = widths[at]
                if child_index < 0 or child_index >= level_counts[n-1] or offset < 0 or width < 1:
                    return List[Int64]()
                if offset+width > d or counts[(n-1)*30+child_index] != width: return List[Int64]()
                let child_offset = sg_block_offset(n-1,child_index,level_counts,counts)
                if child_offset < 0 or child_offset+width*width > child_size: return List[Int64]()
                for row in range(width):
                    for col in range(width):
                        let target = child_offset+row*width+col
                        child[target] = (child[target]+current[(offset+row)*d+offset+col])%SG_PRIME
        let restricted = sg_transpose_forward(n-1,child,level_counts,counts,restriction_counts,
                                              children,offsets,widths,diagonals,partners,coefficients)
        if len(restricted) != child_size: return List[Int64]()
        var h = List[Int](length=9, fill=0)
        var permutation = List[Int](length=9, fill=0)
        for i in range(n-1): h[i] = i
        var index = 0
        var more = True
        while more:
            for i in range(n-1): permutation[i] = h[i]
            permutation[n-1] = n-1
            for i in range(n):
                if permutation[i] == image: permutation[i] = n-1
                elif permutation[i] == n-1: permutation[i] = image
            let rank = sg_rank(permutation,n)
            if rank < 0 or index >= child_size: return List[Int64]()
            output[rank] = restricted[index]
            index += 1
            more = sg_next_permutation(h,n-1)
        if index != child_size: return List[Int64]()
    return output^

@export("symmetric_group_convolution_fft")
fn symmetric_group_convolution_fft(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 725762: return -1
    if input[0] < 1 or input[0] > 9: return -1
    let n = Int(input[0])
    let count = sg_factorial(n)
    if length != c_size_t(1+2*count): return -1
    for i in range(1,Int(length)):
        if input[i] < 0 or input[i] >= SG_PRIME: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(4*count): return -2

    var level_counts = List[Int](length=10, fill=0)
    var shapes = List[Int](length=2700, fill=0)
    var counts = List[Int](length=300, fill=0)
    var basis = List[Int](length=1628100, fill=0)
    var restriction_counts = List[Int](length=300, fill=0)
    var children = List[Int](length=2700, fill=0)
    var offsets = List[Int](length=2700, fill=0)
    var widths = List[Int](length=2700, fill=0)
    var diagonals = List[Int64](length=1447200, fill=0)
    var partners = List[Int](length=1447200, fill=0)
    var coefficients = List[Int64](length=1447200, fill=0)
    if not sg_make_tableau_plan(n,level_counts,shapes,counts,basis,restriction_counts,children,offsets,widths): return -4
    if not sg_make_generators(n,level_counts,counts,basis,diagonals,partners,coefficients): return -4
    var a = List[Int64](length=count, fill=0)
    var b = List[Int64](length=count, fill=0)
    for i in range(count):
        a[i] = input[1+i]
        b[i] = input[1+count+i]
    let left = sg_forward(n,a,level_counts,counts,restriction_counts,children,offsets,widths,diagonals,partners,coefficients)
    if len(left) != count: return -4
    let right = sg_forward(n,b,level_counts,counts,restriction_counts,children,offsets,widths,diagonals,partners,coefficients)
    if len(right) != count: return -4
    var product = List[Int64](length=count, fill=0)
    for shape in range(level_counts[n]):
        let d = counts[n*30+shape]
        let offset = sg_block_offset(n,shape,level_counts,counts)
        if d < 1 or d > SG_BASIS or offset < 0 or offset+d*d > count: return -4
        for row in range(d):
            for col in range(d):
                var value = Int64(0)
                for inner in range(d):
                    value = (value+left[offset+row*d+inner]*right[offset+inner*d+col])%SG_PRIME
                product[offset+row*d+col] = value
    let weighted = sg_weight_blocks(n,product,level_counts,counts,partners,coefficients)
    if len(weighted) != count: return -4
    let result = sg_transpose_forward(n,weighted,level_counts,counts,restriction_counts,children,offsets,widths,
                                      diagonals,partners,coefficients)
    if len(result) != count: return -4
    for i in range(count):
        for byte in range(4): output[4*i+byte] = UInt8((result[i] >> (8*byte)) & 255)
    return Int64(4*count)
