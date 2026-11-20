from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_OPS = 128
comptime MAX_LIVE = 64
comptime MAX_BUCKETS = 64
comptime MAX_PRIORITY = Int64(1000000)

struct Event:
    var priority: Int64
    var id: Int64
    var next: Int
    var active: Bool

    fn __init__(inout self, priority: Int64 = 0, id: Int64 = 0,
        next: Int = MAX_LIVE, active: Bool = False):
        self.priority = priority
        self.id = id
        self.next = next
        self.active = active

struct Calendar:
    var events: InlineArray[Event, 64]
    var heads: InlineArray[Int, 64]
    var bucket_count: Int
    var live: Int
    var next_id: Int64
    var last_priority: Int64
    var last_bucket: Int
    var width_num: Int64
    var width_den: Int64
    var top_num: Int64
    var top_den: Int64

    fn __init__(inout self):
        self.events = InlineArray[Event, 64](fill=Event())
        self.heads = InlineArray[Int, 64](fill=MAX_LIVE)
        self.bucket_count = 2
        self.live = 0
        self.next_id = 0
        self.last_priority = 0
        self.last_bucket = 0
        self.width_num = 1
        self.width_den = 1
        self.top_num = 3
        self.top_den = 2

fn less(a: Event, b: Event) -> Bool:
    return a.priority < b.priority or (a.priority == b.priority and a.id < b.id)

fn gcd(a0: Int64, b0: Int64) -> Int64:
    var a = a0
    var b = b0
    while b != 0:
        let r = a % b
        a = b
        b = r
    return a

fn virtual_bucket(q: Calendar, priority: Int64) -> Int:
    return Int((priority * q.width_den) // q.width_num)

fn reset_cursor(inout q: Calendar, priority: Int64):
    let virtual_index = virtual_bucket(q, priority)
    q.last_bucket = virtual_index % q.bucket_count
    q.top_num = (2 * Int64(virtual_index) + 3) * q.width_num
    q.top_den = 2 * q.width_den

fn insert_event(inout q: Calendar, slot: Int):
    let bucket = virtual_bucket(q, q.events[slot].priority) % q.bucket_count
    var previous = Int(MAX_LIVE)
    var current = q.heads[bucket]
    while current != MAX_LIVE and less(q.events[current], q.events[slot]):
        previous = current
        current = q.events[current].next
    q.events[slot].next = current
    if previous == MAX_LIVE:
        q.heads[bucket] = slot
    else:
        q.events[previous].next = slot

fn new_width(q: Calendar) -> InlineArray[Int64, 2]:
    var ordered = InlineArray[Event, 64]()
    var count = 0
    for i in range(MAX_LIVE):
        let event = q.events[i]
        if not event.active: continue
        var at = count
        while at > 0 and less(event, ordered[at - 1]):
            ordered[at] = ordered[at - 1]
            at -= 1
        ordered[at] = event
        count += 1
    var result = InlineArray[Int64, 2](fill=1)
    if count < 2: return result
    let samples = count if count <= 5 else min(25, 5 + count // 10)
    let gaps = samples - 1
    var sum: Int64 = 0
    for i in range(gaps): sum += ordered[i + 1].priority - ordered[i].priority
    if sum == 0: return result
    var kept_sum: Int64 = 0
    var kept: Int64 = 0
    for i in range(gaps):
        let gap = ordered[i + 1].priority - ordered[i].priority
        if gap * Int64(gaps) <= 2 * sum:
            kept_sum += gap
            kept += 1
    if kept_sum == 0 or kept == 0: return result
    let numerator = 3 * kept_sum
    let divisor = gcd(numerator, kept)
    result[0] = numerator // divisor
    result[1] = kept // divisor
    return result

fn resize(inout q: Calendar, new_count: Int):
    let width = new_width(q)
    q.bucket_count = new_count
    q.width_num = width[0]
    q.width_den = width[1]
    for i in range(MAX_BUCKETS): q.heads[i] = MAX_LIVE
    reset_cursor(q, q.last_priority)
    for slot in range(MAX_LIVE):
        if q.events[slot].active: insert_event(q, slot)

fn enqueue(inout q: Calendar, priority: Int64) -> Bool:
    if priority < 0 or priority > MAX_PRIORITY or priority < q.last_priority or q.live == MAX_LIVE: return False
    var slot = MAX_LIVE
    for i in range(MAX_LIVE):
        if not q.events[i].active:
            slot = i
            break
    if slot == MAX_LIVE: return False
    q.events[slot] = Event(priority, q.next_id, MAX_LIVE, True)
    q.next_id += 1
    q.live += 1
    insert_event(q, slot)
    if q.live > 2 * q.bucket_count: resize(q, q.bucket_count * 2)
    return True

fn dequeue(inout q: Calendar, inout result: Event) -> Bool:
    if q.live == 0: return False
    var bucket = q.last_bucket
    while True:
        let slot = q.heads[bucket]
        if slot != MAX_LIVE and q.events[slot].priority * q.top_den < q.top_num:
            result = q.events[slot]
            q.heads[bucket] = result.next
            q.events[slot].active = False
            q.live -= 1
            q.last_bucket = bucket
            q.last_priority = result.priority
            if q.bucket_count > 2 and Int64(q.live) < Int64(q.bucket_count // 2 - 2): resize(q, q.bucket_count // 2)
            return True
        bucket = (bucket + 1) % q.bucket_count
        q.top_num += 2 * q.width_num
        if bucket == q.last_bucket:
            var minimum = MAX_LIVE
            for i in range(q.bucket_count):
                let head = q.heads[i]
                if head != MAX_LIVE and (minimum == MAX_LIVE or less(q.events[head], q.events[minimum])): minimum = head
            if minimum == MAX_LIVE: return False
            q.last_priority = q.events[minimum].priority
            reset_cursor(q, q.last_priority)
            bucket = q.last_bucket

fn put_i64(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], word: Int):
    let bits = UInt64(value)
    for byte in range(8): output[word * 8 + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("calendar_queue")
fn calendar_queue(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 258: return -1
    let count = input[0]
    if count < 0 or count > MAX_OPS or length != c_size_t(1 + 2 * count): return -1
    var q = Calendar()
    q.bucket_count = 2
    q.width_num = 1
    q.width_den = 1
    q.top_num = 3
    q.top_den = 2
    for i in range(MAX_BUCKETS): q.heads[i] = MAX_LIVE
    for i in range(MAX_LIVE): q.events[i] = Event(0, 0, MAX_LIVE, False)
    var trace = InlineArray[Int64, 256]()
    var dequeued = 0
    for step in range(Int(count)):
        let opcode = input[1 + 2 * step]
        let argument = input[2 + 2 * step]
        if opcode == 1:
            if not enqueue(q, argument): return -1
        elif opcode == 2:
            if argument != 0: return -1
            var event = Event(0, 0, MAX_LIVE, False)
            if not dequeue(q, event): return -1
            trace[2 * dequeued] = event.id
            trace[2 * dequeued + 1] = event.priority
            dequeued += 1
        else:
            return -1
    let bytes = (1 + 2 * dequeued) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    put_i64(Int64(dequeued), output, 0)
    for word in range(2 * dequeued): put_i64(trace[word], output, word + 1)
    return Int64(bytes)
