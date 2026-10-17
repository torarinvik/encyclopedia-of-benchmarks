const MAX_OPS: usize = 32;
const MAX_CAPACITY: usize = 128;
const MAX_WORDS: usize = 320;

struct HashMap {
    keys: [i32; MAX_CAPACITY],
    values: [i32; MAX_CAPACITY],
    occupied: [bool; MAX_CAPACITY],
    capacity: usize,
    size: usize,
}
impl HashMap {
    fn new(capacity: usize) -> Self {
        Self { keys: [0; MAX_CAPACITY], values: [0; MAX_CAPACITY], occupied: [false; MAX_CAPACITY], capacity, size: 0 }
    }
    fn hash(key: i32, capacity: usize) -> usize {
        ((key as u32 & 0x7fff_ffff) as usize) % capacity
    }
    fn resize(&mut self, new_capacity: usize) {
        let old_keys = self.keys;
        let old_values = self.values;
        let old_occupied = self.occupied;
        let old_capacity = self.capacity;
        self.capacity = new_capacity;
        for i in 0..new_capacity { self.occupied[i] = false; }
        for i in 0..old_capacity {
            if !old_occupied[i] { continue; }
            let mut index = Self::hash(old_keys[i], new_capacity);
            while self.occupied[index] { index = (index + 1) % new_capacity; }
            self.keys[index] = old_keys[i];
            self.values[index] = old_values[i];
            self.occupied[index] = true;
        }
    }
    fn find_slot(&self, key: i32) -> usize {
        let mut index = Self::hash(key, self.capacity);
        for _ in 0..self.capacity {
            if !self.occupied[index] { return self.capacity; }
            if self.keys[index] == key { return index; }
            index = (index + 1) % self.capacity;
        }
        self.capacity
    }
    fn put(&mut self, key: i32, value: i32) {
        if self.size > self.capacity / 2 { self.resize(self.capacity * 2); }
        let mut index = Self::hash(key, self.capacity);
        while self.occupied[index] {
            if self.keys[index] == key { self.values[index] = value; return; }
            index = (index + 1) % self.capacity;
        }
        self.keys[index] = key; self.values[index] = value; self.occupied[index] = true; self.size += 1;
    }
    fn delete(&mut self, key: i32) -> bool {
        let mut index = self.find_slot(key);
        if index == self.capacity { return false; }
        self.occupied[index] = false; self.values[index] = 0; index = (index + 1) % self.capacity;
        while self.occupied[index] {
            let k = self.keys[index]; let v = self.values[index];
            self.occupied[index] = false; self.values[index] = 0; self.size -= 1;
            self.put(k, v);
            index = (index + 1) % self.capacity;
        }
        self.size -= 1;
        if self.size > 0 && self.size <= self.capacity / 8 { self.resize(self.capacity / 2); }
        true
    }
}
fn append(words: &mut [i64; MAX_WORDS], count: &mut usize, value: i64) { words[*count] = value; *count += 1; }

#[no_mangle]
pub extern "C" fn linear_probing_hash_map(input: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 98 { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    if !(4..=16).contains(&a[0]) || !(0..=MAX_OPS as i64).contains(&a[1]) { return -1; }
    let op_count = a[1] as usize;
    if length > 2 + 3 * op_count { return -1; }
    let mut map = HashMap::new(a[0] as usize);
    let mut words = [0i64; MAX_WORDS];
    let mut word_count = 0usize;
    let mut pos = 2usize;
    for _ in 0..op_count {
        if pos >= length { return -1; }
        let op = a[pos]; pos += 1;
        if op == 0 {
            if pos + 1 >= length { return -1; }
            let key = a[pos]; let value = a[pos + 1]; pos += 2;
            if key < i32::MIN as i64 || key > i32::MAX as i64 || value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
            map.put(key as i32, value as i32); append(&mut words, &mut word_count, 0); append(&mut words, &mut word_count, 1);
        } else if (1..=3).contains(&op) {
            if pos >= length { return -1; }
            let key = a[pos]; pos += 1;
            if key < i32::MIN as i64 || key > i32::MAX as i64 { return -1; }
            let k = key as i32; let index = map.find_slot(k);
            if op == 1 {
                append(&mut words,&mut word_count,1);
                if index == map.capacity { append(&mut words,&mut word_count,1); append(&mut words,&mut word_count,0); }
                else { append(&mut words,&mut word_count,0); append(&mut words,&mut word_count,map.values[index] as i64); }
            } else if op == 2 { append(&mut words,&mut word_count,2); append(&mut words,&mut word_count,map.delete(k) as i64); }
            else { append(&mut words,&mut word_count,3); append(&mut words,&mut word_count,(index != map.capacity) as i64); }
        } else if op == 4 { append(&mut words,&mut word_count,4); append(&mut words,&mut word_count,map.size as i64); }
        else if op == 5 {
            let mut sorted=[0i32;MAX_OPS]; let mut count=0usize;
            for i in 0..map.capacity { if map.occupied[i] { sorted[count]=map.keys[i]; count+=1; } }
            sorted[..count].sort_unstable();
            append(&mut words,&mut word_count,5); append(&mut words,&mut word_count,count as i64);
            for &key in &sorted[..count] { append(&mut words,&mut word_count,key as i64); }
        } else { return -1; }
    }
    if pos != length || word_count > MAX_WORDS { return -1; }
    let bytes=word_count*8;
    if output.is_null() || output_capacity<bytes { return -2; }
    unsafe {
        for i in 0..word_count { for b in 0..8 { *output.add(8*i+b)=((words[i] as u64)>>(8*b)) as u8; } }
    }
    bytes as i64
}
