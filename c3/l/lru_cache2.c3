module lru_cache2;

const usz MAX_CAPACITY = 64;
const usz MAX_OPERATIONS = 256;
const usz MAP_SIZE = 1024;
const long PUT_SENTINEL = -9223372036854775807L - 1L;

struct CacheNode { int key; int value; int previous; int next; }
struct MapEntry { int key; int node; int state; }

usz hash_key(int key) {
    uint bits = @bitcast(uint, key);
    return (usz)((bits * 2654435761u) & 1023u);
}

int map_find(MapEntry* map, int key) {
    usz slot = hash_key(key);
    for (usz probe = 0; probe < MAP_SIZE; probe++) {
        usz index = (slot + probe) & 1023;
        if (map[index].state == 0) return -1;
        if (map[index].state == 1 && map[index].key == key) return map[index].node;
    }
    return -1;
}

bool map_insert(MapEntry* map, int key, int node) {
    usz slot = hash_key(key), tombstone = MAP_SIZE;
    for (usz probe = 0; probe < MAP_SIZE; probe++) {
        if (map[slot].state == 1 && map[slot].key == key) return false;
        if (map[slot].state == 2 && tombstone == MAP_SIZE) tombstone = slot;
        if (map[slot].state == 0) {
            if (tombstone != MAP_SIZE) slot = tombstone;
            map[slot] = MapEntry{key, node, 1};
            return true;
        }
        slot = (slot + 1) & 1023;
    }
    if (tombstone != MAP_SIZE) { map[tombstone] = MapEntry{key, node, 1}; return true; }
    return false;
}

void map_remove(MapEntry* map, int key) {
    usz slot = hash_key(key);
    for (usz probe = 0; probe < MAP_SIZE; probe++) {
        if (map[slot].state == 0) return;
        if (map[slot].state == 1 && map[slot].key == key) { map[slot].state = 2; return; }
        slot = (slot + 1) & 1023;
    }
}

void unlink_node(CacheNode* nodes, int* head, int* tail, int node) {
    int previous = nodes[node].previous, next = nodes[node].next;
    if (previous == -1) *head = next; else nodes[previous].next = next;
    if (next == -1) *tail = previous; else nodes[next].previous = previous;
}

void link_at_head(CacheNode* nodes, int* head, int* tail, int node) {
    nodes[node].previous = -1;
    nodes[node].next = *head;
    if (*head == -1) *tail = node; else nodes[*head].previous = node;
    *head = node;
}

void promote_node(CacheNode* nodes, int* head, int* tail, int node) {
    if (*head == node) return;
    unlink_node(nodes, head, tail, node);
    link_at_head(nodes, head, tail, node);
}

void store_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long lru_cache2(long* input, usz length, char* output, usz capacity) @export("lru_cache2") {
    if (input == null || length < 2 || length > 771) return -1;
    if (input[0] < 2 || input[0] > 64 || input[1] < 0 || input[1] > 256) return -1;
    int cache_capacity = (int)input[0], operation_count = (int)input[1];
    if (length != 2 + (usz)operation_count * 3) return -1;
    CacheNode[MAX_CAPACITY] nodes = zeroed;
    MapEntry[MAP_SIZE] map = zeroed;
    int[MAX_OPERATIONS] seen_put_keys = zeroed;
    int seen_count = 0, head = -1, tail = -1, node_count = 0;
    long[MAX_OPERATIONS] results = zeroed;
    for (int operation = 0; operation < operation_count; operation++) {
        usz base = 2 + (usz)operation * 3;
        long opcode_value = input[base], first = input[base + 1], second = input[base + 2];
        if (opcode_value < 0 || opcode_value > 4) return -1;
        int opcode = (int)opcode_value;
        if (opcode == 0) {
            if (first < -2147483648L || first > 2147483647L || second < -2147483648L || second > 2147483647L) return -1;
            for (int index = 0; index < seen_count; index++) if (seen_put_keys[index] == (int)first) return -1;
            seen_put_keys[seen_count++] = (int)first;
            int node;
            if (node_count < cache_capacity) node = node_count++;
            else { node = tail; map_remove(&map[0], nodes[node].key); unlink_node(&nodes[0], &head, &tail, node); }
            nodes[node].key = (int)first; nodes[node].value = (int)second;
            if (!map_insert(&map[0], nodes[node].key, node)) return -1;
            link_at_head(&nodes[0], &head, &tail, node);
            results[operation] = PUT_SENTINEL;
        } else if (opcode == 1) {
            if (first < -2147483648L || first > 2147483647L || second != 0) return -1;
            int node = map_find(&map[0], (int)first);
            if (node == -1) return -1;
            promote_node(&nodes[0], &head, &tail, node);
            results[operation] = nodes[node].value;
        } else {
            if (first != 0 || second != 0) return -1;
            if (opcode == 2) results[operation] = node_count;
            else if (opcode == 3) results[operation] = cache_capacity;
            else results[operation] = node_count == 0 ? 1 : 0;
        }
    }
    usz output_bytes = (usz)operation_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (int operation = 0; operation < operation_count; operation++) store_i64(output, (usz)operation * 8, results[operation]);
    return (long)output_bytes;
}
