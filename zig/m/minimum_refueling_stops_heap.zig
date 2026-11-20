/// Greedy minimum refueling stops using a bounded max-heap.
export fn minimum_refueling_stops_heap(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 20) return -2;
    const input = input_opt.?;
    const target = input[0];
    const start_fuel = input[1];
    const count_value = input[2];
    if (target < 1 or target > 2000 or start_fuel < 0 or start_fuel > 2000
        or count_value < 0 or count_value > 8) return -2;
    const count: usize = @intCast(count_value);
    if (length != 3 + 2 * count) return -2;
    var previous: i64 = 0;
    for (0..count) |i| {
        const position = input[3 + 2 * i];
        const fuel = input[4 + 2 * i];
        if (position <= previous or position >= target or fuel < 1 or fuel > 2000) return -2;
        previous = position;
    }

    var heap: [8]i64 = @splat(0);
    var heap_length: usize = 0;
    var next_station: usize = 0;
    var reach = start_fuel;
    var stops: i64 = 0;
    while (reach < target) {
        while (next_station < count and input[3 + 2 * next_station] <= reach) {
            var child = heap_length;
            heap_length += 1;
            heap[child] = input[4 + 2 * next_station];
            while (child > 0) {
                const parent = (child - 1) / 2;
                if (heap[parent] >= heap[child]) break;
                const temporary = heap[parent];
                heap[parent] = heap[child];
                heap[child] = temporary;
                child = parent;
            }
            next_station += 1;
        }
        if (heap_length == 0) return -1;
        const maximum = heap[0];
        heap_length -= 1;
        if (heap_length > 0) {
            heap[0] = heap[heap_length];
            var parent: usize = 0;
            while (true) {
                const left = 2 * parent + 1;
                const right = left + 1;
                if (left >= heap_length) break;
                var child = left;
                if (right < heap_length and heap[right] > heap[left]) child = right;
                if (heap[parent] >= heap[child]) break;
                const temporary = heap[parent];
                heap[parent] = heap[child];
                heap[child] = temporary;
                parent = child;
            }
        }
        reach += maximum;
        stops += 1;
    }
    return stops;
}
