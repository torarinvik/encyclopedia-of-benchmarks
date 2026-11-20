from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

const MAX_VALUES = 1024
const MERGE_INPUTS = 2
const INITIAL_RUN_SIZE = 16

fn build_run(values: List[Int64], run_size: Int, merge_inputs: Int,
             first_run: Int, run_count: Int, ascending: Bool) -> List[Int64]:
    if run_count == 1:
        let start = first_run * run_size
        let length = min(run_size, len(values) - start)
        var run = List[Int64](capacity=length)
        for i in range(length): run.append(values[start + i])
        for i in range(1, length):
            let value = run[i]
            var position = i
            while position > 0:
                let previous = run[position - 1]
                if ascending and value >= previous: break
                if not ascending and value <= previous: break
                run[position] = previous
                position -= 1
            run[position] = value
        return run

    let quotient = run_count // merge_inputs
    let remainder = run_count % merge_inputs
    var children = List[List[Int64]](capacity=merge_inputs)
    var lengths = List[Int](capacity=merge_inputs)
    var positions = List[Int](capacity=merge_inputs)
    var next_run = first_run
    var total = 0
    for lane in range(merge_inputs):
        let child_count = quotient + (1 if lane < remainder else 0)
        if child_count > 0:
            let child = build_run(values, run_size, merge_inputs, next_run,
                                  child_count, not ascending)
            lengths.append(len(child))
            positions.append(0)
            total += len(child)
            children.append(child)
            next_run += child_count

    var merged = List[Int64](capacity=total)
    for _ in range(total):
        var best_lane = -1
        var best_value: Int64 = 0
        for lane in range(len(children)):
            if positions[lane] >= lengths[lane]: continue
            let candidate = children[lane][lengths[lane] - 1 - positions[lane]]
            if best_lane < 0 or (ascending and candidate < best_value) or (not ascending and candidate > best_value):
                best_lane = lane
                best_value = candidate
        merged.append(best_value)
        positions[best_lane] += 1
    return merged

@export("oscillating_merge_sort")
fn oscillating_merge_sort(values: UnsafePointer[Int64, MutAnyOrigin],
                          length: c_size_t) abi("C") -> None:
    if length == 0 or length > c_size_t(MAX_VALUES) or values == UnsafePointer[Int64, MutAnyOrigin](): return
    let count = Int(length)
    var original = List[Int64](capacity=count)
    for i in range(count): original.append(values[i])
    let run_count = (count + INITIAL_RUN_SIZE - 1) // INITIAL_RUN_SIZE
    let sorted = build_run(original, INITIAL_RUN_SIZE, MERGE_INPUTS, 0, run_count, True)
    for i in range(count): values[i] = sorted[i]
