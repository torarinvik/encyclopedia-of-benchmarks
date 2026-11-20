from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("polyphase_merge_sort")
fn polyphase_merge_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C"):
    if values == UnsafePointer[Int64, MutAnyOrigin]() or length < 2 or length > 256: return
    let n = Int(length)
    var tapes = InlineArray[InlineArray[Int64, 256], 3]()
    var starts = InlineArray[InlineArray[UInt32, 34], 3]()
    var run_lengths = InlineArray[InlineArray[UInt32, 34], 3]()
    var counts = InlineArray[UInt32, 3]()
    var read_indices = InlineArray[UInt32, 3]()
    var write_offsets = InlineArray[UInt32, 3]()
    var roles = InlineArray[UInt32, 3]()
    roles[0] = 0
    roles[1] = 1
    roles[2] = 2

    let initial_runs = UInt32((n + 7) / 8)
    var quota_a: UInt32 = 1
    var quota_b: UInt32 = 0
    while quota_a + quota_b < initial_runs:
        let next = quota_a + quota_b
        quota_b = quota_a
        quota_a = next
    var run: UInt32 = 0
    for _ in range(Int(quota_a)):
        let slot = Int(counts[0])
        if run < initial_runs:
            let source = Int(run) * 8
            let run_length = min(n - source, 8)
            let start = Int(write_offsets[0])
            starts[0][slot] = write_offsets[0]
            run_lengths[0][slot] = UInt32(run_length)
            counts[0] += 1
            for i in range(run_length): tapes[0][start + i] = values[source + i]
            for i in range(1, run_length):
                let value = tapes[0][start + i]
                var position = i
                while position > 0 and tapes[0][start + position - 1] > value:
                    tapes[0][start + position] = tapes[0][start + position - 1]
                    position -= 1
                tapes[0][start + position] = value
            write_offsets[0] += UInt32(run_length)
        else:
            starts[0][slot] = write_offsets[0]
            run_lengths[0][slot] = 0
            counts[0] += 1
        run += 1
    for _ in range(Int(quota_b)):
        let slot = Int(counts[1])
        if run < initial_runs:
            let source = Int(run) * 8
            let run_length = min(n - source, 8)
            let start = Int(write_offsets[1])
            starts[1][slot] = write_offsets[1]
            run_lengths[1][slot] = UInt32(run_length)
            counts[1] += 1
            for i in range(run_length): tapes[1][start + i] = values[source + i]
            for i in range(1, run_length):
                let value = tapes[1][start + i]
                var position = i
                while position > 0 and tapes[1][start + position - 1] > value:
                    tapes[1][start + position] = tapes[1][start + position - 1]
                    position -= 1
                tapes[1][start + position] = value
            write_offsets[1] += UInt32(run_length)
        else:
            starts[1][slot] = write_offsets[1]
            run_lengths[1][slot] = 0
            counts[1] += 1
        run += 1

    var remaining_total = counts[0] + counts[1]
    while remaining_total > 1:
        let input_a = Int(roles[0])
        let input_b = Int(roles[1])
        let output = Int(roles[2])
        let available_a = counts[input_a] - read_indices[input_a]
        let available_b = counts[input_b] - read_indices[input_b]
        if available_a == 0 or available_b == 0: break
        counts[output] = 0
        read_indices[output] = 0
        write_offsets[output] = 0
        let pairs = Int(min(available_a, available_b))
        for _ in range(pairs):
            let left_slot = Int(read_indices[input_a])
            let right_slot = Int(read_indices[input_b])
            read_indices[input_a] += 1
            read_indices[input_b] += 1
            let left_start = Int(starts[input_a][left_slot])
            let right_start = Int(starts[input_b][right_slot])
            let left_length = Int(run_lengths[input_a][left_slot])
            let right_length = Int(run_lengths[input_b][right_slot])
            let output_slot = Int(counts[output])
            counts[output] += 1
            let output_start = Int(write_offsets[output])
            var left = 0
            var right = 0
            var written = 0
            while left < left_length and right < right_length:
                if tapes[input_a][left_start + left] <= tapes[input_b][right_start + right]:
                    tapes[output][output_start + written] = tapes[input_a][left_start + left]
                    left += 1
                else:
                    tapes[output][output_start + written] = tapes[input_b][right_start + right]
                    right += 1
                written += 1
            while left < left_length:
                tapes[output][output_start + written] = tapes[input_a][left_start + left]
                left += 1
                written += 1
            while right < right_length:
                tapes[output][output_start + written] = tapes[input_b][right_start + right]
                right += 1
                written += 1
            starts[output][output_slot] = UInt32(output_start)
            run_lengths[output][output_slot] = UInt32(written)
            write_offsets[output] += UInt32(written)

        let left_a = counts[input_a] - read_indices[input_a]
        let left_b = counts[input_b] - read_indices[input_b]
        remaining_total = left_a + left_b + counts[output]
        if remaining_total <= 1 or (left_a == 0 and left_b == 0): break
        if left_a > 0:
            roles[0] = UInt32(input_a)
            roles[1] = UInt32(output)
            roles[2] = UInt32(input_b)
        else:
            roles[0] = UInt32(output)
            roles[1] = UInt32(input_b)
            roles[2] = UInt32(input_a)

    for tape in range(3):
        if read_indices[tape] < counts[tape]:
            let slot = Int(read_indices[tape])
            if Int(run_lengths[tape][slot]) == n:
                let start = Int(starts[tape][slot])
                for i in range(n): values[i] = tapes[tape][start + i]
                return
