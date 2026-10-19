from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cpu_better(mode: Int64, a: Int64, b: Int64, arrival: InlineArray[Int64, 32], burst: InlineArray[Int64, 32], remaining: InlineArray[Int64, 32], priority: InlineArray[Int64, 32]) -> Bool:
    if mode == 1:
        return burst[a] < burst[b] or (burst[a] == burst[b] and (arrival[a] < arrival[b] or (arrival[a] == arrival[b] and a < b)))
    if mode == 2:
        return remaining[a] < remaining[b] or (remaining[a] == remaining[b] and (arrival[a] < arrival[b] or (arrival[a] == arrival[b] and a < b)))
    return priority[a] < priority[b] or (priority[a] == priority[b] and a < b)

@export("cpu_scheduling_algorithms")
fn cpu_scheduling_algorithms(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 131: return -1
    let mode = input[0]
    let raw_n = input[1]
    let quantum = input[2]
    if mode < 0 or mode > 5 or raw_n < 0 or raw_n > 32 or quantum < 1 or quantum > 32: return -1
    let n = raw_n
    if length != 3 + 4 * n: return -1
    var ids = InlineArray[Int64, 32](0)
    var arrival = InlineArray[Int64, 32](0)
    var burst = InlineArray[Int64, 32](0)
    var priority = InlineArray[Int64, 32](0)
    var remaining = InlineArray[Int64, 32](0)
    var completion = InlineArray[Int64, 32](-1)
    var first_run = InlineArray[Int64, 32](-1)
    var order = InlineArray[Int64, 32](0)
    for i in range(n):
        let base = 3 + 4 * i
        ids[i] = input[base]
        arrival[i] = input[base + 1]
        burst[i] = input[base + 2]
        priority[i] = input[base + 3]
        if ids[i] < 0 or ids[i] >= 32 or arrival[i] < 0 or arrival[i] > 256 or burst[i] < 1 or burst[i] > 32 or priority[i] < -32 or priority[i] > 32: return -1
        for j in range(i):
            if ids[j] == ids[i]: return -1
        remaining[i] = burst[i]
        order[i] = i
    let bytes = n * 56
    if bytes != 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes): return -2
    if mode == 0 or mode == 5:
        for i in range(1, n):
            let key = order[i]
            var j = i
            while j > 0 and arrival[order[j - 1]] > arrival[key]:
                order[j] = order[j - 1]
                j -= 1
            order[j] = key
    var time: Int64 = 0
    if mode == 0:
        for p in range(n):
            let i = order[p]
            if time < arrival[i]: time = arrival[i]
            first_run[i] = time
            time += burst[i]
            completion[i] = time
    elif mode == 1 or mode == 3:
        var done: Int64 = 0
        while done < n:
            var best = n
            for i in range(n):
                if completion[i] >= 0 or arrival[i] > time: continue
                if best == n or cpu_better(mode, i, best, arrival, burst, remaining, priority): best = i
            if best == n: time += 1
            else:
                first_run[best] = time
                time += burst[best]
                completion[best] = time
                done += 1
    elif mode == 2 or mode == 4:
        var done: Int64 = 0
        while done < n:
            var best = n
            for i in range(n):
                if remaining[i] <= 0 or arrival[i] > time: continue
                if best == n or cpu_better(mode, i, best, arrival, burst, remaining, priority): best = i
            if best == n: time += 1
            else:
                if first_run[best] < 0: first_run[best] = time
                remaining[best] -= 1
                time += 1
                if remaining[best] == 0:
                    completion[best] = time
                    done += 1
    else:
        var queue = InlineArray[Int64, 64](0)
        var head: Int64 = 0
        var tail: Int64 = 0
        var size: Int64 = 0
        var next_arrival: Int64 = 0
        var done: Int64 = 0
        while done < n:
            while next_arrival < n and arrival[order[next_arrival]] <= time:
                queue[tail] = order[next_arrival]
                tail = (tail + 1) % 64
                size += 1
                next_arrival += 1
            if size == 0: time += 1
            else:
                let current = queue[head]
                head = (head + 1) % 64
                size -= 1
                let run_for = quantum if quantum < remaining[current] else remaining[current]
                for slot in range(run_for):
                    if first_run[current] < 0: first_run[current] = time
                    remaining[current] -= 1
                    time += 1
                    while next_arrival < n and arrival[order[next_arrival]] <= time:
                        queue[tail] = order[next_arrival]
                        tail = (tail + 1) % 64
                        size += 1
                        next_arrival += 1
                if remaining[current] > 0:
                    queue[tail] = current
                    tail = (tail + 1) % 64
                    size += 1
                else:
                    completion[current] = time
                    done += 1
    var stage = InlineArray[UInt8, 1792](0)
    for i in range(n):
        let turnaround = completion[i] - arrival[i]
        var fields = InlineArray[Int64, 7](0)
        fields[0] = ids[i]
        fields[1] = arrival[i]
        fields[2] = burst[i]
        fields[3] = completion[i]
        fields[4] = turnaround
        fields[5] = turnaround - burst[i]
        fields[6] = first_run[i] - arrival[i]
        for f in range(7):
            let bits = UInt64(fields[f])
            for b in range(8): stage[i * 56 + f * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    for i in range(bytes): output[i] = stage[i]
    return bytes
