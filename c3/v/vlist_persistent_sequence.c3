module vlist_persistent_sequence;

const usz MAX_Q = 48;
const usz MAX_CONS = 32;
const usz MAX_ROOTS = 49;
const usz MAX_BLOCKS = 6;
const usz MAX_SLOTS = 63;
const usz MAX_PARSEABLE = 146;

struct Block {
    long previous_block;
    long previous_offset;
    long capacity;
    long last_used;
    long base;
}

fn long list_length(Block* blocks, usz block_count, long* root_blocks,
                    long* root_offsets, usz root) {
    long block_id = root_blocks[root];
    long offset = root_offsets[root];
    long total = 0;
    while (block_id >= 0) {
        if ((usz)block_id >= block_count || offset < 0 || offset > blocks[block_id].last_used) return -1;
        total += offset + 1;
        offset = blocks[block_id].previous_offset;
        block_id = blocks[block_id].previous_block;
    }
    total
}

fn long list_nth(Block* blocks, usz block_count, long* data,
                 long* root_blocks, long* root_offsets, usz root, long index) {
    long block_id = root_blocks[root];
    long offset = root_offsets[root];
    long remaining = index;
    while (block_id >= 0) {
        if ((usz)block_id >= block_count || offset < 0 || offset > blocks[block_id].last_used) return -1000001;
        if (remaining <= offset) return data[blocks[block_id].base + offset - remaining];
        remaining -= offset + 1;
        offset = blocks[block_id].previous_offset;
        block_id = blocks[block_id].previous_block;
    }
    -1000001
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) {
        output[offset + i] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

fn long vlist_persistent_sequence(long* input, usz length, char* output, usz capacity)
    @export("vlist_persistent_sequence") {
    if (input == null || length < 1 || length > MAX_PARSEABLE) return -1;
    long q_word = input[0];
    if (q_word < 1 || q_word > (long)MAX_Q || length != 1 + 3 * (usz)q_word) return -1;
    usz q = (usz)q_word;

    Block[MAX_BLOCKS] blocks = {};
    long[MAX_SLOTS] data = {};
    long[MAX_ROOTS] root_blocks = {};
    long[MAX_ROOTS] root_offsets = {};
    long[MAX_Q] results = {};
    for (usz i = 0; i < MAX_ROOTS; i++) { root_blocks[i] = -1; root_offsets[i] = -1; }
    usz block_count = 0;
    usz root_count = 1;
    usz slot_count = 0;
    usz cons_count = 0;
    bool query_phase = false;
    usz at = 1;
    for (usz op = 0; op < q; op++) {
        long tag = input[at++];
        long root_word = input[at++];
        long arg = input[at++];
        if (tag < 0 || tag > 3 || root_word < 0 || (usz)root_word >= root_count) return -1;
        usz root = (usz)root_word;
        if (tag == 0) {
            if (query_phase || root != root_count - 1 || cons_count >= MAX_CONS || arg < -1000000 || arg > 1000000) return -1;
            long block_id = root_blocks[root];
            long offset = root_offsets[root];
            if (block_id < 0) {
                if (cons_count != 0 || block_count != 0 || slot_count >= MAX_SLOTS) return -1;
                Block* block = &blocks[block_count];
                block.previous_block = -1;
                block.previous_offset = -1;
                block.capacity = 1;
                block.last_used = 0;
                block.base = (long)slot_count;
                data[slot_count] = arg;
                block_id = (long)block_count;
                offset = 0;
                block_count++;
                slot_count++;
            } else {
                if ((usz)block_id >= block_count || offset != blocks[block_id].last_used) return -1;
                Block* block = &blocks[block_id];
                if (offset + 1 < block.capacity) {
                    offset++;
                    data[block.base + offset] = arg;
                    block.last_used = offset;
                } else {
                    long next_capacity = block.capacity * 2;
                    if (block_count >= MAX_BLOCKS || slot_count + (usz)next_capacity > MAX_SLOTS) return -1;
                    Block* next = &blocks[block_count];
                    next.previous_block = block_id;
                    next.previous_offset = offset;
                    next.capacity = next_capacity;
                    next.last_used = 0;
                    next.base = (long)slot_count;
                    data[slot_count] = arg;
                    block_id = (long)block_count;
                    offset = 0;
                    block_count++;
                    slot_count += (usz)next_capacity;
                }
            }
            if (root_count >= MAX_ROOTS) return -1;
            root_blocks[root_count] = block_id;
            root_offsets[root_count] = offset;
            results[op] = (long)root_count;
            root_count++;
            cons_count++;
        } else {
            query_phase = true;
            if (tag == 1) {
                if (arg != -1 || list_length(&blocks[0], block_count, &root_blocks[0], &root_offsets[0], root) <= 0) return -1;
                long block_id = root_blocks[root];
                long offset = root_offsets[root];
                if (offset > 0) offset--;
                else { offset = blocks[block_id].previous_offset; block_id = blocks[block_id].previous_block; }
                if (root_count >= MAX_ROOTS) return -1;
                root_blocks[root_count] = block_id;
                root_offsets[root_count] = offset;
                results[op] = (long)root_count;
                root_count++;
            } else if (tag == 2) {
                long n = list_length(&blocks[0], block_count, &root_blocks[0], &root_offsets[0], root);
                if (n < 0 || arg < 0 || arg >= n) return -1;
                long value = list_nth(&blocks[0], block_count, &data[0], &root_blocks[0], &root_offsets[0], root, arg);
                if (value == -1000001) return -1;
                results[op] = value;
            } else {
                if (arg != -1) return -1;
                long n = list_length(&blocks[0], block_count, &root_blocks[0], &root_offsets[0], root);
                if (n < 0) return -1;
                results[op] = n;
            }
        }
    }
    usz bytes = q * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < q; i++) store_i64_le(output, i * 8, results[i]);
    return (long)bytes;
}
