struct Heap<T> {
    items: Vec<T>,
    compare: fn(&T, &T) -> bool,
}
impl<T> Heap<T> {
    fn new(compare: fn(&T, &T) -> bool) -> Self {
        Self { items: Vec::new(), compare }
    }
    fn add(&mut self, value: T) {
        self.items.push(value);
        let mut index = self.items.len() - 1;
        while index > 0 {
            let parent = (index - 1) / 2;
            if !(self.compare)(&self.items[index], &self.items[parent]) { break; }
            self.items.swap(index, parent);
            index = parent;
        }
    }
    fn peek(&self) -> Option<&T> { self.items.first() }
    fn pop(&mut self) -> Option<T> {
        if self.items.is_empty() { return None; }
        let root = self.items.swap_remove(0);
        if !self.items.is_empty() {
            let mut index = 0;
            loop {
                let mut child = index;
                let left = index * 2 + 1;
                let right = left + 1;
                if left < self.items.len() && (self.compare)(&self.items[left], &self.items[child]) { child = left; }
                if right < self.items.len() && (self.compare)(&self.items[right], &self.items[child]) { child = right; }
                if child == index { break; }
                self.items.swap(index, child);
                index = child;
            }
        }
        Some(root)
    }
}
impl<T: Ord> Heap<T> {
    fn new_min() -> Self { Self::new(|left, right| left < right) }
}
fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn binary_heap_min_push_peek_pop(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || !(2..=257).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let raw_count = input[0];
    if !(1..=256).contains(&raw_count) || length != raw_count as usize + 1 { return -1; }
    if input[1..].iter().any(|&value| !(-2_147_483_648..=2_147_483_647).contains(&value)) { return -1; }
    let count = raw_count as usize;
    let output_bytes = 8 * count;
    if output.is_null() || capacity < output_bytes { return -2; }
    let result = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    let mut heap = Heap::<i64>::new_min();
    for &value in &input[1..] { heap.add(value); }
    for index in 0..count {
        let minimum = *heap.peek().expect("heap has one item before each extraction");
        let _extracted = heap.pop().expect("heap has one item for each extraction");
        store_i64_le(result, 8 * index, minimum);
    }
    output_bytes as i64
}
