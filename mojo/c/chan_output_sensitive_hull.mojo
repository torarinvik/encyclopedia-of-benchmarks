from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

# Unverified Chan hull draft; no compiler or benchmark has run.
fn chan_turn(inout x: InlineArray[Int64, 32], inout y: InlineArray[Int64, 32], a: Int, b: Int, c: Int) -> Int64:
    return (x[b]-x[a])*(y[c]-y[a]) - (y[b]-y[a])*(x[c]-x[a])

fn chan_less(inout x: InlineArray[Int64, 32], inout y: InlineArray[Int64, 32], a: Int, b: Int) -> Bool:
    return x[a] < x[b] or (x[a] == x[b] and y[a] < y[b])

fn chan_group(inout x: InlineArray[Int64, 32], inout y: InlineArray[Int64, 32], begin: Int, count: Int,
              inout hulls: InlineArray[Int, 32], offset: Int) -> Int:
    var order = InlineArray[Int, 32](fill=0)
    var scratch = InlineArray[Int, 32](fill=0)
    var chain = InlineArray[Int, 64](fill=0)
    for i in range(count): order[i] = begin+i
    var width = 1
    while width < count:
        var block = 0
        while block < count:
            let middle = min(block+width, count)
            let finish = min(block+2*width, count)
            var left = block
            var right = middle
            var dest = block
            while left < middle and right < finish:
                if chan_less(x, y, order[right], order[left]):
                    scratch[dest] = order[right]
                    right += 1
                else:
                    scratch[dest] = order[left]
                    left += 1
                dest += 1
            while left < middle:
                scratch[dest] = order[left]
                left += 1
                dest += 1
            while right < finish:
                scratch[dest] = order[right]
                right += 1
                dest += 1
            block += 2*width
        for i in range(count): order[i] = scratch[i]
        width *= 2
    if count == 1:
        hulls[offset] = order[0]
        return 1
    var used = 0
    for i in range(count):
        while used >= 2 and chan_turn(x, y, chain[used-2], chain[used-1], order[i]) <= 0: used -= 1
        chain[used] = order[i]
        used += 1
    let lower = used
    var i = count-1
    while i > 0:
        i -= 1
        while used > lower and chan_turn(x, y, chain[used-2], chain[used-1], order[i]) <= 0: used -= 1
        chain[used] = order[i]
        used += 1
    used -= 1
    for j in range(used): hulls[offset+j] = chain[j]
    return used

fn chan_tangent(inout x: InlineArray[Int64, 32], inout y: InlineArray[Int64, 32],
                inout hulls: InlineArray[Int, 32], offset: Int, count: Int, query: Int) -> Int:
    if count == 1: return hulls[offset]
    if count == 2:
        if chan_turn(x, y, query, hulls[offset], hulls[offset+1]) > 0: return hulls[offset]
        return hulls[offset+1]
    let initial_up = chan_turn(x, y, query, hulls[offset], hulls[offset+1]) > 0
    var lo = 0
    var hi = count
    while lo < hi:
        let mid = lo+(hi-lo)//2
        let before = chan_turn(x, y, query, hulls[offset+mid], hulls[offset+(mid+count-1)%count]) > 0
        let after = chan_turn(x, y, query, hulls[offset+mid], hulls[offset+(mid+1)%count]) > 0
        if before and after: return hulls[offset+mid]
        let below = mid != 0 and chan_turn(x, y, query, hulls[offset+mid], hulls[offset]) > 0
        let above = mid != 0 and chan_turn(x, y, query, hulls[offset], hulls[offset+mid]) > 0
        var search_left = after or above
        if initial_up: search_left = after and below
        if search_left: hi = mid
        else: lo = mid+1
    return -1

@export("chan_output_sensitive_hull")
fn chan_output_sensitive_hull(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 66: return -1
    if input[0] < 3 or input[0] > 32: return -1
    let n = Int(input[0])
    if length != c_size_t(1+2*n): return -1
    var x = InlineArray[Int64, 32](fill=0)
    var y = InlineArray[Int64, 32](fill=0)
    for i in range(n):
        x[i] = input[1+2*i]
        y[i] = input[2+2*i]
        if x[i] < -1000 or x[i] > 1000 or y[i] < -1000 or y[i] > 1000: return -1
        for j in range(i):
            if x[i] == x[j] and y[i] == y[j]: return -1
    for i in range(n):
        for j in range(i+1, n):
            for k in range(j+1, n):
                if chan_turn(x, y, i, j, k) == 0: return -1
    var start = 0
    for i in range(1, n):
        if chan_less(x, y, i, start): start = i
    var guess = min(4, n)
    while True:
        var hulls = InlineArray[Int, 32](fill=0)
        var offsets = InlineArray[Int, 32](fill=0)
        var sizes = InlineArray[Int, 32](fill=0)
        var group_of = InlineArray[Int, 32](fill=0)
        var position = InlineArray[Int, 32](fill=-1)
        var groups = 0
        var stored = 0
        var begin = 0
        while begin < n:
            let finish = min(n, begin+guess)
            offsets[groups] = stored
            sizes[groups] = chan_group(x, y, begin, finish-begin, hulls, stored)
            for i in range(begin, finish): group_of[i] = groups
            for i in range(sizes[groups]): position[hulls[stored+i]] = i
            stored += sizes[groups]
            groups += 1
            begin = finish
        var result = InlineArray[Int, 32](fill=0)
        result[0] = start
        var used = 1
        for step in range(guess):
            let current = result[used-1]
            var candidate = -1
            for g in range(groups):
                var local = -1
                if g == group_of[current]:
                    if position[current] < 0: return -1
                    if sizes[g] > 1: local = hulls[offsets[g]+(position[current]+1)%sizes[g]]
                else:
                    local = chan_tangent(x, y, hulls, offsets[g], sizes[g], current)
                    if local < 0: return -1
                if local >= 0 and (candidate < 0 or chan_turn(x, y, current, candidate, local) < 0): candidate = local
            if candidate < 0: return -1
            if candidate == start:
                let byte_count = 16*used
                if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
                for i in range(used):
                    for axis in range(2):
                        var value = x[result[i]]
                        if axis == 1: value = y[result[i]]
                        let bits = bitcast[UInt64](value)
                        for b in range(8): output[16*i+8*axis+b] = UInt8((bits >> UInt64(8*b)) & 255)
                return Int64(byte_count)
            if used == n: return -1
            result[used] = candidate
            used += 1
        if guess == n: return -1
        guess = min(n, guess*guess)
