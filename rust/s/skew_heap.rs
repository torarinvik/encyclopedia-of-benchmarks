const MAX_OPERATIONS: usize = 64;
const MAX_LIVE_VALUES: usize = 32;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_VALUES: usize = 1024;

#[derive(Clone, Copy, Default)]
struct Node { value: i32, left: i32, right: i32, next_free: i32 }
struct SkewHeap { nodes: [Node; MAX_LIVE_VALUES], root: i32, free_head: i32, count: usize }

impl SkewHeap {
    fn new() -> Self {
        let mut heap = Self { nodes: [Node::default(); MAX_LIVE_VALUES], root: -1, free_head: 0, count: 0 };
        for i in 0..MAX_LIVE_VALUES {
            heap.nodes[i].left = -1; heap.nodes[i].right = -1;
            heap.nodes[i].next_free = if i + 1 < MAX_LIVE_VALUES { (i + 1) as i32 } else { -1 };
        }
        heap
    }
    fn merge(&mut self, mut first: i32, mut second: i32) -> i32 {
        if first < 0 { return second; }
        if second < 0 { return first; }
        if self.nodes[first as usize].value > self.nodes[second as usize].value { std::mem::swap(&mut first, &mut second); }
        let node = first as usize; let old_right = self.nodes[node].right;
        self.nodes[node].right = self.nodes[node].left;
        self.nodes[node].left = self.merge(old_right, second);
        first
    }
    fn insert(&mut self, value: i32) -> bool {
        if self.free_head < 0 { return false; }
        let node = self.free_head as usize; self.free_head = self.nodes[node].next_free;
        self.nodes[node] = Node { value, left: -1, right: -1, next_free: -1 };
        self.root = self.merge(self.root, node as i32); self.count += 1; true
    }
    fn pop(&mut self) -> i32 {
        let node = self.root as usize; let value = self.nodes[node].value;
        self.root = self.merge(self.nodes[node].left, self.nodes[node].right);
        self.nodes[node].next_free = self.free_head; self.free_head = node as i32; self.count -= 1; value
    }
    fn clear(&mut self) { *self = Self::new(); }
}

#[no_mangle]
pub unsafe extern "C" fn skew_heap(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = values[0] as usize;
    if length != 1 + 2 * operation_count || length > MAX_INPUT_LENGTH - 1 { return -1; }
    let mut heap = SkewHeap::new(); let mut answers = [0i64; MAX_OUTPUT_VALUES]; let mut answer_count = 0usize;
    for operation in 0..operation_count {
        let opcode = values[1 + 2 * operation]; let argument = values[2 + 2 * operation];
        if !(0..=5).contains(&opcode) { return -1; }
        if opcode == 0 {
            if argument < i32::MIN as i64 || argument > i32::MAX as i64 || heap.count == MAX_LIVE_VALUES { return -1; }
            if !heap.insert(argument as i32) { return -1; }
        } else {
            if argument != 0 { return -1; }
            if opcode == 1 { if heap.root < 0 { return -1; } answers[answer_count] = heap.nodes[heap.root as usize].value as i64; answer_count += 1; }
            else if opcode == 2 { if heap.root < 0 { return -1; } answers[answer_count] = heap.pop() as i64; answer_count += 1; }
            else if opcode == 3 {
                let mut snapshot = [0i32; MAX_LIVE_VALUES]; let mut snapshot_count = 0usize;
                while heap.root >= 0 { snapshot[snapshot_count] = heap.pop(); snapshot_count += 1; }
                for i in 0..snapshot_count { if !heap.insert(snapshot[i]) { return -1; } answers[answer_count] = snapshot[i] as i64; answer_count += 1; }
            } else if opcode == 4 { heap.clear(); }
            else { answers[answer_count] = if heap.count == 0 { 1 } else { 0 }; answer_count += 1; }
        }
    }
    let output_bytes = answer_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..answer_count { let bits = answers[i] as u64; for byte in 0..8 { *output.add(i * 8 + byte) = (bits >> (8 * byte)) as u8; } }
    output_bytes as i64
}
