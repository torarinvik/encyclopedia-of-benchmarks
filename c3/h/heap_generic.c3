module heap_generic;

const usz MAX_OPERATIONS = 512;
const usz MAX_ITEMS = 128;
const usz ID_CAPACITY = 4096;
const usz MAX_INPUT_LENGTH = 1537;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_byte(ulong hash, uint byte) {
    return (hash ^ (ulong)(byte & 255)) * FNV_PRIME;
}

fn ulong hash_i32(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (uint shift = 0; shift < 32; shift += 8) hash = hash_byte(hash, (uint)(bits >> shift));
    return hash;
}

fn void swap_items(long* ids, long* priorities, int* positions, usz first, usz second) {
    long temporary = ids[first]; ids[first] = ids[second]; ids[second] = temporary;
    temporary = priorities[first]; priorities[first] = priorities[second]; priorities[second] = temporary;
    positions[(usz)ids[first]] = (int)first;
    positions[(usz)ids[second]] = (int)second;
}

fn void heapify_up(long* ids, long* priorities, int* positions, usz index) {
    while (index > 0) {
        usz parent = (index - 1) / 2;
        if (priorities[index] <= priorities[parent]) break;
        swap_items(ids, priorities, positions, index, parent);
        index = parent;
    }
}

fn void heapify_down(long* ids, long* priorities, int* positions, usz heap_size, usz index) {
    while (true) {
        usz best = index;
        usz left = 2 * index + 1;
        usz right = left + 1;
        if (left < heap_size && priorities[left] > priorities[best]) best = left;
        if (right < heap_size && priorities[right] > priorities[best]) best = right;
        if (best == index) return;
        swap_items(ids, priorities, positions, index, best);
        index = best;
    }
}

fn void erase_item(long* ids, long* priorities, int* positions, usz* heap_size, long item_id) {
    usz index = (usz)positions[(usz)item_id];
    usz last = *heap_size - 1;
    positions[(usz)item_id] = -1;
    if (index != last) {
        ids[index] = ids[last];
        priorities[index] = priorities[last];
        positions[(usz)ids[index]] = (int)index;
    }
    *heap_size = last;
    if (index < *heap_size) {
        heapify_up(ids, priorities, positions, index);
        heapify_down(ids, priorities, positions, *heap_size, index);
    }
}

fn long heap_generic(long* values, usz length) @export("heap_generic") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long operation_count_value = values[0];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS ||
        length != 1 + 3 * (usz)operation_count_value) return -1;

    long[MAX_ITEMS] ids;
    long[MAX_ITEMS] priorities;
    int[ID_CAPACITY] positions;
    bool[ID_CAPACITY] used_ids;
    for (usz i = 0; i < ID_CAPACITY; i++) { positions[i] = -1; used_ids[i] = false; }
    usz heap_size = 0;
    ulong hash = FNV_OFFSET;

    for (usz operation = 0; operation < (usz)operation_count_value; operation++) {
        long opcode = values[1 + 3 * operation];
        long item_id = values[2 + 3 * operation];
        long priority = values[3 + 3 * operation];
        bool present = false;
        long returned_id = 0, returned_priority = 0;

        if (opcode == 0) {
            if (item_id < 0 || item_id >= (long)ID_CAPACITY || priority < -2147483648 || priority > 2147483647 ||
                used_ids[(usz)item_id] || heap_size >= MAX_ITEMS) return -1;
            for (usz i = 0; i < heap_size; i++) if (priorities[i] == priority) return -1;
            used_ids[(usz)item_id] = true;
            ids[heap_size] = item_id;
            priorities[heap_size] = priority;
            positions[(usz)item_id] = (int)heap_size;
            heap_size++;
            heapify_up(&ids[0], &priorities[0], &positions[0], heap_size - 1);
        } else if (opcode == 1 || opcode == 2) {
            if (item_id != 0 || priority != 0) return -1;
            if (heap_size != 0) {
                present = true;
                returned_id = ids[0];
                returned_priority = priorities[0];
                if (opcode == 2) erase_item(&ids[0], &priorities[0], &positions[0], &heap_size, returned_id);
            }
        } else if (opcode == 3) {
            if (item_id < 0 || item_id >= (long)ID_CAPACITY || priority < -2147483648 || priority > 2147483647 ||
                positions[(usz)item_id] < 0) return -1;
            usz index = (usz)positions[(usz)item_id];
            for (usz i = 0; i < heap_size; i++)
                if (i != index && priorities[i] == priority) return -1;
            priorities[index] = priority;
            heapify_up(&ids[0], &priorities[0], &positions[0], index);
            heapify_down(&ids[0], &priorities[0], &positions[0], heap_size, index);
        } else if (opcode == 4) {
            if (item_id < 0 || item_id >= (long)ID_CAPACITY || priority != 0 || positions[(usz)item_id] < 0) return -1;
            erase_item(&ids[0], &priorities[0], &positions[0], &heap_size, item_id);
        } else return -1;

        hash = hash_byte(hash, (uint)opcode);
        hash = hash_byte(hash, present ? 1 : 0);
        if (present) {
            hash = hash_i32(hash, returned_id);
            hash = hash_i32(hash, returned_priority);
        }
    }
    return (long)hash;
}
