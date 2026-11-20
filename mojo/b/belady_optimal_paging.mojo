from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const PAGE_COUNT = 16
const MAX_REQUESTS = 64
const MAX_INPUT_LENGTH = 67
const CHECKSUM_RADIX: Int64 = 33281

@export("belady_optimal_paging")
fn belady_optimal_paging(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let capacity_value = input[0]
    let count_value = input[1]
    if capacity_value < 1 or capacity_value > 8 or count_value < 0 or count_value > MAX_REQUESTS:
        return -1
    if length != 2 + count_value:
        return -1
    let count = Int(count_value)

    var requests = InlineArray[Int, 64](fill=0)
    for time in range(count):
        let page = input[2 + time]
        if page < 0 or page >= PAGE_COUNT:
            return -1
        requests[time] = Int(page)

    var next_after = InlineArray[Int, 1024](fill=0)
    var next_position = InlineArray[Int, 16](fill=count)
    var cursor = count
    while cursor > 0:
        cursor -= 1
        for page in range(PAGE_COUNT):
            next_after[cursor * PAGE_COUNT + page] = next_position[page]
        next_position[requests[cursor]] = cursor

    var resident = InlineArray[Bool, 16](fill=False)
    var resident_count = 0
    var misses: Int64 = 0
    var eviction_checksum: Int64 = 0
    for time in range(count):
        let requested = requests[time]
        if resident[requested]:
            continue
        misses += 1
        if resident_count == Int(capacity_value):
            var victim = -1
            var farthest = -1
            for page in range(PAGE_COUNT):
                if not resident[page]:
                    continue
                let following = next_after[time * PAGE_COUNT + page]
                if following > farthest:
                    victim = page
                    farthest = following
            resident[victim] = False
            resident_count -= 1
            eviction_checksum += Int64((time + 1) * (victim + 1))
        resident[requested] = True
        resident_count += 1
    return misses * CHECKSUM_RADIX + eviction_checksum
