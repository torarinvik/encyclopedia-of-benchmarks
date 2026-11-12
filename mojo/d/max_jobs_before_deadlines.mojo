from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn max_jobs_before(left_duration: Int64, left_id: Int, right_duration: Int64, right_id: Int) -> Bool:
    return left_duration < right_duration or (left_duration == right_duration and left_id < right_id)

@export("max_jobs_before_deadlines")
fn max_jobs_before_deadlines(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 25:
        return -1
    let count_value = input[0]
    if count_value < 0 or count_value > 12 or Int(length) != 1 + 2 * Int(count_value):
        return -1
    let count = Int(count_value)
    var deadlines = InlineArray[Int64, 12](fill=0)
    var durations = InlineArray[Int64, 12](fill=0)
    var ids = InlineArray[Int, 12](fill=0)
    for i in range(count):
        let deadline = input[1 + 2 * i]
        let duration = input[2 + 2 * i]
        if deadline < 0 or deadline > 1000 or duration < 1 or duration > 1000:
            return -1
        deadlines[i] = deadline
        durations[i] = duration
        ids[i] = i
    for i in range(1, count):
        let deadline = deadlines[i]
        let duration = durations[i]
        let id = ids[i]
        var position = i
        while position > 0 and deadlines[position - 1] > deadline:
            deadlines[position] = deadlines[position - 1]
            durations[position] = durations[position - 1]
            ids[position] = ids[position - 1]
            position -= 1
        deadlines[position] = deadline
        durations[position] = duration
        ids[position] = id

    var heap_durations = InlineArray[Int64, 12](fill=0)
    var heap_ids = InlineArray[Int, 12](fill=0)
    var heap_size = 0
    var completed: Int64 = 0
    for end in range(count):
        let index = count - 1 - end
        var heap_index = heap_size
        heap_size += 1
        while heap_index > 0:
            let parent = (heap_index - 1) // 2
            if not max_jobs_before(durations[index], ids[index], heap_durations[parent], heap_ids[parent]):
                break
            heap_durations[heap_index] = heap_durations[parent]
            heap_ids[heap_index] = heap_ids[parent]
            heap_index = parent
        heap_durations[heap_index] = durations[index]
        heap_ids[heap_index] = ids[index]
        let lower = if index == 0: 0 else: deadlines[index - 1]
        var interval = deadlines[index] - lower
        while interval > 0 and heap_size > 0:
            let remaining = heap_durations[0]
            let id = heap_ids[0]
            heap_size -= 1
            if heap_size > 0:
                let last_duration = heap_durations[heap_size]
                let last_id = heap_ids[heap_size]
                var root = 0
                while 2 * root + 1 < heap_size:
                    var child = 2 * root + 1
                    if child + 1 < heap_size and max_jobs_before(heap_durations[child + 1], heap_ids[child + 1], heap_durations[child], heap_ids[child]):
                        child += 1
                    if not max_jobs_before(heap_durations[child], heap_ids[child], last_duration, last_id):
                        break
                    heap_durations[root] = heap_durations[child]
                    heap_ids[root] = heap_ids[child]
                    root = child
                heap_durations[root] = last_duration
                heap_ids[root] = last_id
            if remaining <= interval:
                interval -= remaining
                completed += 1
            else:
                var heap_index = heap_size
                heap_size += 1
                while heap_index > 0:
                    let parent = (heap_index - 1) // 2
                    if not max_jobs_before(remaining - interval, id, heap_durations[parent], heap_ids[parent]):
                        break
                    heap_durations[heap_index] = heap_durations[parent]
                    heap_ids[heap_index] = heap_ids[parent]
                    heap_index = parent
                heap_durations[heap_index] = remaining - interval
                heap_ids[heap_index] = id
                interval = 0
    return completed
