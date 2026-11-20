module minimum_refueling_stops_heap;

fn long minimum_refueling_stops_heap(long* input, usz length) @export("minimum_refueling_stops_heap") {
    if (input == null || length < 3 || length > 20) return -2;
    long target = input[0];
    long start_fuel = input[1];
    long count_value = input[2];
    if (target < 1 || target > 2000 || start_fuel < 0 || start_fuel > 2000
        || count_value < 0 || count_value > 8) return -2;
    usz count = (usz)count_value;
    if (length != 3 + 2 * count) return -2;
    long previous = 0;
    for (usz i = 0; i < count; i++) {
        long position = input[3 + 2 * i];
        long fuel = input[4 + 2 * i];
        if (position <= previous || position >= target || fuel < 1 || fuel > 2000) return -2;
        previous = position;
    }

    long[8] heap = zeroed;
    usz heap_length = 0;
    usz next_station = 0;
    long reach = start_fuel;
    long stops = 0;
    while (reach < target) {
        while (next_station < count && input[3 + 2 * next_station] <= reach) {
            usz child = heap_length;
            heap_length++;
            heap[child] = input[4 + 2 * next_station];
            while (child > 0) {
                usz parent = (child - 1) / 2;
                if (heap[parent] >= heap[child]) break;
                long temporary = heap[parent];
                heap[parent] = heap[child];
                heap[child] = temporary;
                child = parent;
            }
            next_station++;
        }
        if (heap_length == 0) return -1;
        long maximum = heap[0];
        heap_length--;
        if (heap_length > 0) {
            heap[0] = heap[heap_length];
            usz parent = 0;
            while (true) {
                usz left = 2 * parent + 1;
                usz right = left + 1;
                if (left >= heap_length) break;
                usz child = left;
                if (right < heap_length && heap[right] > heap[left]) child = right;
                if (heap[parent] >= heap[child]) break;
                long temporary = heap[parent];
                heap[parent] = heap[child];
                heap[child] = temporary;
                parent = child;
            }
        }
        reach += maximum;
        stops++;
    }
    return stops;
}
