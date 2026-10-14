/// Patience sorting with lower-bound piles and a binary min-heap merge.
const MAX_INPUT_LENGTH = 1024;

fn nodeLess(keys: []const i64, left: usize, right: usize) bool {
    return keys[left] < keys[right] or (keys[left] == keys[right] and left < right);
}

fn siftDown(keys: []const i64, heap: []usize, heap_length: usize, start_root: usize) void {
    var root = start_root;
    while (root < heap_length / 2) {
        var child = root * 2 + 1;
        if (child + 1 < heap_length and nodeLess(keys, heap[child + 1], heap[child])) child += 1;
        if (!nodeLess(keys, heap[child], heap[root])) break;
        const temporary = heap[root]; heap[root] = heap[child]; heap[child] = temporary;
        root = child;
    }
}

export fn patience_sort(values: [*]i64, length: usize) void {
    if (length < 2 or length > MAX_INPUT_LENGTH) return;
    var keys: [MAX_INPUT_LENGTH]i64 = undefined;
    var pile_tops: [MAX_INPUT_LENGTH]usize = undefined;
    var next_in_pile: [MAX_INPUT_LENGTH]usize = undefined;
    var heap: [MAX_INPUT_LENGTH]usize = undefined;
    var pile_count: usize = 0;
    for (0..length) |index| {
        keys[index] = values[index];
        next_in_pile[index] = length;
        var low: usize = 0;
        var high = pile_count;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (keys[pile_tops[middle]] >= keys[index]) high = middle else low = middle + 1;
        }
        if (low == pile_count) {
            pile_tops[pile_count] = index;
            pile_count += 1;
        } else {
            next_in_pile[index] = pile_tops[low];
            pile_tops[low] = index;
        }
    }
    for (0..pile_count) |pile| heap[pile] = pile_tops[pile];
    var heap_length = pile_count;
    var start = heap_length / 2;
    while (start > 0) {
        start -= 1;
        siftDown(keys[0..], heap[0..], heap_length, start);
    }
    var output: usize = 0;
    while (heap_length > 0) {
        const node = heap[0];
        values[output] = keys[node];
        output += 1;
        const successor = next_in_pile[node];
        if (successor < length) {
            heap[0] = successor;
        } else {
            heap_length -= 1;
            if (heap_length > 0) heap[0] = heap[heap_length];
        }
        if (heap_length > 0) siftDown(keys[0..], heap[0..], heap_length, 0);
    }
}
