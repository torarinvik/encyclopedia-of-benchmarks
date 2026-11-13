from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_MACHINES = 8
alias MAX_TASKS = 32
alias MAX_PARSEABLE_WORDS = 99

fn event_less(left: Int, right: Int, finish: InlineArray[Int64, MAX_TASKS]) -> Bool:
    if finish[left] != finish[right]:
        return finish[left] < finish[right]
    return left < right

fn heap_push(inout heap: InlineArray[Int, MAX_TASKS], inout size: Int,
             task: Int, finish: InlineArray[Int64, MAX_TASKS]):
    var position = size
    size += 1
    while position > 0:
        let parent = (position - 1) // 2
        if not event_less(task, heap[parent], finish):
            break
        heap[position] = heap[parent]
        position = parent
    heap[position] = task

fn heap_pop(inout heap: InlineArray[Int, MAX_TASKS], inout size: Int,
            finish: InlineArray[Int64, MAX_TASKS]) -> Int:
    let minimum = heap[0]
    size -= 1
    if size == 0:
        return minimum
    let replacement = heap[size]
    var position = 0
    while True:
        let left = 2 * position + 1
        if left >= size:
            break
        let right = left + 1
        var child = left
        if right < size and event_less(heap[right], heap[left], finish):
            child = right
        if not event_less(heap[child], replacement, finish):
            break
        heap[position] = heap[child]
        position = child
    heap[position] = replacement
    return minimum

@export("online_temporary_task_load_balancing")
fn online_temporary_task_load_balancing(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or Int(length) < 2 or Int(length) > MAX_PARSEABLE_WORDS:
        return -1
    if input[0] < 1 or input[0] > Int64(MAX_MACHINES) or input[1] < 0 or input[1] > Int64(MAX_TASKS):
        return -1
    let machine_count = Int(input[0])
    let task_count = Int(input[1])
    if Int(length) != 2 + 3 * task_count:
        return -1

    var arrivals = InlineArray[Int64, MAX_TASKS]()
    var weights = InlineArray[Int64, MAX_TASKS]()
    var finish = InlineArray[Int64, MAX_TASKS]()
    var assigned = InlineArray[Int, MAX_TASKS]()
    var loads = InlineArray[Int64, MAX_MACHINES]()
    var heap = InlineArray[Int, MAX_TASKS]()
    var heap_size = 0
    var staged = InlineArray[Int64, MAX_TASKS + 1]()
    var previous_arrival: Int64 = -1
    for task in range(task_count):
        let at = input[2 + 3 * task]
        let amount = input[3 + 3 * task]
        let duration = input[4 + 3 * task]
        if at < 0 or at > 1000 or at < previous_arrival or amount < 1 or amount > 1000 or duration < 1 or duration > 1000 or at + duration > 2000:
            return -1
        arrivals[task] = at
        weights[task] = amount
        finish[task] = at + duration
        previous_arrival = at

    var peak: Int64 = 0
    for task in range(task_count):
        while heap_size > 0 and finish[heap[0]] <= arrivals[task]:
            let expired = heap_pop(heap, heap_size, finish)
            loads[assigned[expired]] -= weights[expired]
        var machine = 0
        for candidate in range(1, machine_count):
            if loads[candidate] < loads[machine]:
                machine = candidate
        assigned[task] = machine
        loads[machine] += weights[task]
        if loads[machine] > peak:
            peak = loads[machine]
        heap_push(heap, heap_size, task, finish)

    staged[0] = peak
    for task in range(task_count):
        staged[task + 1] = Int64(assigned[task])
    let output_words = task_count + 1
    let output_bytes = 8 * output_words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < output_bytes:
        return -2
    for word in range(output_words):
        let bits = UInt64(staged[word])
        for byte in range(8):
            output[8 * word + byte] = UInt8((bits >> (8 * byte)) & 255)
    return Int64(output_bytes)
