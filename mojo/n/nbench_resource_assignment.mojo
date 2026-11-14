# Independently implemented bounded NBench assignment profile.
# Attribution and redistribution notice: benchmarks/n/nbench_resource_assignment/LICENSE.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn assignment_mark(cost: InlineArray[Int, 64], inout marks: InlineArray[Int, 64], n: Int) -> Int:
    for i in range(n * n): marks[i] = 0
    var assigned = 0
    var changed = True
    while changed:
        changed = False
        for axis in range(2):
            for line in range(n):
                var count = 0
                var selected = 0
                for p in range(n):
                    let cell = line * n + p if axis == 0 else p * n + line
                    if cost[cell] == 0 and marks[cell] == 0:
                        count += 1
                        selected = p
                if count == 1:
                    let row = line if axis == 0 else selected
                    let col = selected if axis == 0 else line
                    marks[row * n + col] = 1
                    assigned += 1
                    changed = True
                    for p in range(n):
                        let other = p * n + col if axis == 0 else row * n + p
                        if p != line and cost[other] == 0: marks[other] = 2
    if assigned == n: return assigned
    for row in range(n):
        for col in range(n):
            let cell = row * n + col
            if cost[cell] == 0 and marks[cell] == 0:
                marks[cell] = 1
                assigned += 1
                for p in range(n):
                    if p != col and cost[row * n + p] == 0: marks[row * n + p] = 2
                    if p != row and cost[p * n + col] == 0: marks[p * n + col] = 2
                break
    return assigned

fn assignment_adjust(inout cost: InlineArray[Int, 64], marks: InlineArray[Int, 64], n: Int) -> Bool:
    var rows = InlineArray[Bool, 8](fill=False)
    var cols = InlineArray[Bool, 8](fill=False)
    for row in range(n):
        rows[row] = True
        for col in range(n):
            if marks[row * n + col] == 1: rows[row] = False
    var changed = True
    while changed:
        changed = False
        for row in range(n):
            if rows[row]:
                for col in range(n):
                    if cost[row * n + col] == 0: cols[col] = True
        for col in range(n):
            if cols[col]:
                for row in range(n):
                    if marks[row * n + col] == 1 and not rows[row]:
                        rows[row] = True
                        changed = True
    var minimum = 9223372036854775807
    for row in range(n):
        if rows[row]:
            for col in range(n):
                if not cols[col] and cost[row * n + col] < minimum: minimum = cost[row * n + col]
    if minimum == 9223372036854775807: return False
    for row in range(n):
        for col in range(n):
            let cell = row * n + col
            if rows[row] and not cols[col]: cost[cell] -= minimum
            elif not rows[row] and cols[col]: cost[cell] += minimum
    return True

@export("nbench_resource_assignment")
fn nbench_resource_assignment(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let raw = input[0]
    if raw < 1 or raw > 8: return -1
    let n = Int(raw)
    if Int(length) != 1 + n * n: return -1
    var cost = InlineArray[Int, 64](fill=0)
    for i in range(n * n):
        if input[i + 1] < 0 or input[i + 1] > 1000: return -1
        cost[i] = Int(input[i + 1])
    for axis in range(2):
        for line in range(n):
            var minimum = 9223372036854775807
            for p in range(n):
                let cell = line * n + p if axis == 0 else p * n + line
                if cost[cell] < minimum: minimum = cost[cell]
            for p in range(n):
                let cell = line * n + p if axis == 0 else p * n + line
                cost[cell] -= minimum
    var marks = InlineArray[Int, 64](fill=0)
    var done = False
    for attempt in range(2049):
        if assignment_mark(cost, marks, n) == n:
            done = True
            break
        if not assignment_adjust(cost, marks, n): return -1
    if not done: return -1
    var result = InlineArray[Int, 8](fill=0)
    var seen = InlineArray[Bool, 8](fill=False)
    for row in range(n):
        var selected = n
        for col in range(n):
            if marks[row * n + col] == 1:
                if selected != n: return -1
                selected = col
        if selected == n: return -1
        if seen[selected]: return -1
        seen[selected] = True
        result[row] = selected
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(n * 4): return -2
    for row in range(n):
        output[row * 4] = UInt8(result[row])
        for byte in range(1, 4): output[row * 4 + byte] = 0
    return Int64(n * 4)
