from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

struct RuasEvent(Copyable):
    var x: Int64
    var y1: Int64
    var y2: Int64
    var delta: Int64

@export("rectangle_union_area_sweep")
fn rectangle_union_area_sweep(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 258: return -1
    if input[0] < 0 or input[0] > 64: return -1
    let count = Int(input[0])
    if Int(length) != 1 + 4 * count: return -1

    var ys = InlineArray[Int64, 128]()
    var events = InlineArray[RuasEvent, 128](fill=RuasEvent(0, 0, 0, 0))
    var y_count = 0
    var event_count = 0
    for i in range(count):
        let x1 = input[1 + 4 * i]
        let y1 = input[2 + 4 * i]
        let x2 = input[3 + 4 * i]
        let y2 = input[4 + 4 * i]
        if x1 < -1_000_000_000 or x1 > 1_000_000_000 or x2 < -1_000_000_000 or x2 > 1_000_000_000
            or y1 < -1_000_000_000 or y1 > 1_000_000_000 or y2 < -1_000_000_000 or y2 > 1_000_000_000
            or x1 >= x2 or y1 >= y2: return -1
        ys[y_count] = y1
        ys[y_count + 1] = y2
        y_count += 2
        events[event_count] = RuasEvent(x=x1, y1=y1, y2=y2, delta=1)
        events[event_count + 1] = RuasEvent(x=x2, y1=y1, y2=y2, delta=-1)
        event_count += 2
    if count == 0: return 0

    var start = y_count / 2
    while start > 0:
        start -= 1
        var root = start
        while root * 2 + 1 < y_count:
            var child = root * 2 + 1
            if child + 1 < y_count and ys[child] < ys[child + 1]: child += 1
            if ys[root] >= ys[child]: break
            let value = ys[root]
            ys[root] = ys[child]
            ys[child] = value
            root = child
    var end_value = y_count
    while end_value > 1:
        end_value -= 1
        let value = ys[0]
        ys[0] = ys[end_value]
        ys[end_value] = value
        var root = 0
        while root * 2 + 1 < end_value:
            var child = root * 2 + 1
            if child + 1 < end_value and ys[child] < ys[child + 1]: child += 1
            if ys[root] >= ys[child]: break
            let swapped = ys[root]
            ys[root] = ys[child]
            ys[child] = swapped
            root = child

    var unique_count = 1
    for i in range(1, y_count):
        if ys[i] != ys[unique_count - 1]:
            ys[unique_count] = ys[i]
            unique_count += 1

    start = event_count / 2
    while start > 0:
        start -= 1
        var root = start
        while root * 2 + 1 < event_count:
            var child = root * 2 + 1
            if child + 1 < event_count and events[child].x < events[child + 1].x: child += 1
            if events[root].x >= events[child].x: break
            let value = events[root]
            events[root] = events[child]
            events[child] = value
            root = child
    end_value = event_count
    while end_value > 1:
        end_value -= 1
        let value = events[0]
        events[0] = events[end_value]
        events[end_value] = value
        var root = 0
        while root * 2 + 1 < end_value:
            var child = root * 2 + 1
            if child + 1 < end_value and events[child].x < events[child + 1].x: child += 1
            if events[root].x >= events[child].x: break
            let swapped = events[root]
            events[root] = events[child]
            events[child] = swapped
            root = child

    var cover = InlineArray[Int64, 512]()
    var covered = InlineArray[Int64, 512]()
    var stack_node = InlineArray[Int32, 32]()
    var stack_left = InlineArray[Int32, 32]()
    var stack_right = InlineArray[Int32, 32]()
    var stack_phase = InlineArray[Int32, 32]()
    let intervals = unique_count - 1
    var area: Int64 = 0
    var previous_x = events[0].x
    var event = 0
    while event < event_count:
        let x = events[event].x
        area += covered[1] * (x - previous_x)
        var finish = event
        while finish < event_count and events[finish].x == x: finish += 1
        for pass in range(2):
            let delta = Int64(1 - 2 * pass)
            for i in range(event, finish):
                if events[i].delta != delta: continue
                var low = 0
                var high = unique_count
                while low < high:
                    let middle = low + (high - low) / 2
                    if ys[middle] < events[i].y1: low = middle + 1
                    else: high = middle
                let ql = low
                low = 0
                high = unique_count
                while low < high:
                    let middle = low + (high - low) / 2
                    if ys[middle] < events[i].y2: low = middle + 1
                    else: high = middle
                let qr = low

                var stack_size = 1
                stack_node[0] = 1
                stack_left[0] = 0
                stack_right[0] = Int32(intervals)
                stack_phase[0] = 0
                while stack_size > 0:
                    stack_size -= 1
                    let node = Int(stack_node[stack_size])
                    let left = Int(stack_left[stack_size])
                    let right = Int(stack_right[stack_size])
                    let phase = stack_phase[stack_size]
                    if phase == 1:
                        if cover[node] > 0: covered[node] = ys[right] - ys[left]
                        elif right - left == 1: covered[node] = 0
                        else: covered[node] = covered[node * 2] + covered[node * 2 + 1]
                    elif ql <= left and right <= qr:
                        cover[node] += delta
                        if cover[node] > 0: covered[node] = ys[right] - ys[left]
                        elif right - left == 1: covered[node] = 0
                        else: covered[node] = covered[node * 2] + covered[node * 2 + 1]
                    else:
                        let middle = left + (right - left) / 2
                        stack_node[stack_size] = Int32(node)
                        stack_left[stack_size] = Int32(left)
                        stack_right[stack_size] = Int32(right)
                        stack_phase[stack_size] = 1
                        stack_size += 1
                        if qr > middle:
                            stack_node[stack_size] = Int32(node * 2 + 1)
                            stack_left[stack_size] = Int32(middle)
                            stack_right[stack_size] = Int32(right)
                            stack_phase[stack_size] = 0
                            stack_size += 1
                        if ql < middle:
                            stack_node[stack_size] = Int32(node * 2)
                            stack_left[stack_size] = Int32(left)
                            stack_right[stack_size] = Int32(middle)
                            stack_phase[stack_size] = 0
                            stack_size += 1
        previous_x = x
        event = finish
    return area
