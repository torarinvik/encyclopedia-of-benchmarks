module library_sort;
const usz MAX_ITEMS = 256;
const usz MAX_CAPACITY = 512;

fn usz find_insertion_index(long* data, bool* occupied, usz capacity, long value) {
    usz low = 0;
    usz high = capacity;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        long probe = 2147483647;
        for (usz index = middle; index < capacity; index++) {
            if (occupied[index]) { probe = data[index]; break; }
        }
        if (probe != 2147483647 && probe <= value) low = middle + 1;
        else high = middle;
    }
    return low;
}

fn void insert_at_end(long* data, bool* occupied, usz capacity, long value) {
    usz last = capacity - 1;
    long left = (long)last - 1;
    while (left >= 0 && occupied[(usz)left]) left--;
    if (left < 0) return;
    for (usz index = (usz)left; index < last; index++) data[index] = data[index + 1];
    occupied[(usz)left] = true;
    data[last] = value;
}

fn void insert_value(long* data, bool* occupied, usz capacity, long value) {
    usz position = find_insertion_index(data, occupied, capacity, value);
    if (position >= capacity) { insert_at_end(data, occupied, capacity, value); return; }
    if (!occupied[position]) { data[position] = value; occupied[position] = true; return; }

    usz right = position;
    while (right < capacity && occupied[right]) right++;
    long left = (long)position - 1;
    while (left >= 0 && occupied[(usz)left]) left--;
    bool can_go_right = right < capacity;
    bool can_go_left = left >= 0;
    if (can_go_right && (!can_go_left || right - position <= position - (usz)left)) {
        usz index = right;
        while (index > position) { data[index] = data[index - 1]; index--; }
        occupied[right] = true;
        data[position] = value;
    } else if (can_go_left) {
        usz gap = (usz)left;
        for (usz index = gap; index + 1 < position; index++) data[index] = data[index + 1];
        occupied[gap] = true;
        data[position - 1] = value;
    }
}

fn void library_sort(long* values, usz length) @export("library_sort") {
    if (values == null || length < 2 || length > MAX_ITEMS) return;
    usz capacity = 2 * length;
    long[MAX_CAPACITY] data;
    long[MAX_ITEMS] temporary;
    bool[MAX_CAPACITY] occupied = {};
    usz filled = 1;
    usz next = 1;
    usz round = 0;
    usz middle = capacity / 2;
    data[middle] = values[0];
    occupied[middle] = true;

    while (next < length) {
        usz batch = (usz)1 << round;
        if (batch > length - next) batch = length - next;
        for (usz index = 0; index < batch; index++) {
            insert_value(&data[0], &occupied[0], capacity, values[next + index]);
            filled++;
        }
        next += batch;
        round++;
        if (next < length) {
            usz at = 0;
            for (usz index = 0; index < capacity; index++) {
                if (occupied[index]) { temporary[at] = data[index]; at++; }
            }
            for (usz index = 0; index < capacity; index++) occupied[index] = false;
            for (usz index = 0; index < filled; index++) {
                usz slot = index * capacity / filled;
                data[slot] = temporary[index];
                occupied[slot] = true;
            }
        }
    }

    usz output = 0;
    for (usz index = 0; index < capacity; index++) {
        if (occupied[index]) { values[output] = data[index]; output++; }
    }
}
