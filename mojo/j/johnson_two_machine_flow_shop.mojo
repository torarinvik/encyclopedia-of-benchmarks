from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_JOBS = 8
alias MAX_TIME = 1000

@export("johnson_two_machine_flow_shop")
fn johnson_two_machine_flow_shop(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1:
        return -1
    if input[0] < 1 or input[0] > MAX_JOBS:
        return -1
    let count = Int(input[0])
    if length != 1 + 2 * count:
        return -1
    var first = InlineArray[Int64, MAX_JOBS]()
    var second = InlineArray[Int64, MAX_JOBS]()
    var early = InlineArray[Int, MAX_JOBS]()
    var late = InlineArray[Int, MAX_JOBS]()
    var early_count = 0
    var late_count = 0
    for job in range(count):
        first[job] = input[1 + 2 * job]
        second[job] = input[2 + 2 * job]
        if first[job] < 0 or first[job] > MAX_TIME or second[job] < 0 or second[job] > MAX_TIME:
            return -1
        let is_early = first[job] < second[job]
        var position = early_count if is_early else late_count
        while position > 0:
            let previous = early[position - 1] if is_early else late[position - 1]
            let comes_before = (
                first[job] < first[previous] or
                (first[job] == first[previous] and job < previous)
            ) if is_early else (
                second[job] > second[previous] or
                (second[job] == second[previous] and job < previous)
            )
            if not comes_before:
                break
            if is_early:
                early[position] = previous
            else:
                late[position] = previous
            position -= 1
        if is_early:
            early[position] = job
            early_count += 1
        else:
            late[position] = job
            late_count += 1
    var first_finish: Int64 = 0
    var second_finish: Int64 = 0
    for index in range(count):
        let job = early[index] if index < early_count else late[index - early_count]
        first_finish += first[job]
        second_finish = max(second_finish, first_finish) + second[job]
    return second_finish
