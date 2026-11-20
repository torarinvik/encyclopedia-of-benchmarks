const MAX_OPS: usize = 128;
const MAX_LIVE: usize = 64;
const MAX_BUCKETS: usize = 64;
const MAX_PRIORITY: i64 = 1_000_000;
const MAX_INPUT: usize = 1 + 2 * MAX_OPS + 1;

#[derive(Clone, Copy, Default)]
struct Event {
    priority: i64,
    id: i64,
    next: usize,
    active: bool,
}

fn less(a: Event, b: Event) -> bool {
    a.priority < b.priority || (a.priority == b.priority && a.id < b.id)
}

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let r = a % b; a = b; b = r; }
    a
}

struct Calendar {
    events: [Event; MAX_LIVE],
    heads: [usize; MAX_BUCKETS],
    buckets: usize,
    live: usize,
    next_id: i64,
    last_priority: i64,
    last_bucket: usize,
    width_num: i64,
    width_den: i64,
    top_num: i64,
    top_den: i64,
}

impl Calendar {
    fn new() -> Self {
        Self { events: [Event { next: MAX_LIVE, ..Event::default() }; MAX_LIVE],
            heads: [MAX_LIVE; MAX_BUCKETS], buckets: 2, live: 0, next_id: 0,
            last_priority: 0, last_bucket: 0, width_num: 1, width_den: 1,
            top_num: 3, top_den: 2 }
    }

    fn virtual_bucket(&self, priority: i64) -> usize {
        (priority * self.width_den / self.width_num) as usize
    }

    fn reset_cursor(&mut self, priority: i64) {
        let virtual_index = self.virtual_bucket(priority);
        self.last_bucket = virtual_index % self.buckets;
        self.top_num = (2 * virtual_index as i64 + 3) * self.width_num;
        self.top_den = 2 * self.width_den;
    }

    fn insert(&mut self, slot: usize) {
        let bucket = self.virtual_bucket(self.events[slot].priority) % self.buckets;
        let mut previous = MAX_LIVE;
        let mut current = self.heads[bucket];
        while current != MAX_LIVE && less(self.events[current], self.events[slot]) {
            previous = current;
            current = self.events[current].next;
        }
        self.events[slot].next = current;
        if previous == MAX_LIVE { self.heads[bucket] = slot; }
        else { self.events[previous].next = slot; }
    }

    fn new_width(&self) -> (i64, i64) {
        let mut ordered = [Event::default(); MAX_LIVE];
        let mut count = 0;
        for event in self.events.iter().copied().filter(|event| event.active) {
            let mut at = count;
            while at > 0 && less(event, ordered[at - 1]) {
                ordered[at] = ordered[at - 1];
                at -= 1;
            }
            ordered[at] = event;
            count += 1;
        }
        if count < 2 { return (1, 1); }
        let samples = if count <= 5 { count } else { (5 + count / 10).min(25) };
        let gap_count = samples - 1;
        let mut sum = 0i64;
        for i in 0..gap_count { sum += ordered[i + 1].priority - ordered[i].priority; }
        if sum == 0 { return (1, 1); }
        let mut kept_sum = 0i64;
        let mut kept = 0i64;
        for i in 0..gap_count {
            let gap = ordered[i + 1].priority - ordered[i].priority;
            if gap * gap_count as i64 <= 2 * sum { kept_sum += gap; kept += 1; }
        }
        if kept_sum == 0 || kept == 0 { return (1, 1); }
        let numerator = 3 * kept_sum;
        let denominator = kept;
        let divisor = gcd(numerator, denominator);
        (numerator / divisor, denominator / divisor)
    }

    fn resize(&mut self, buckets: usize) {
        let (num, den) = self.new_width();
        self.buckets = buckets;
        self.width_num = num;
        self.width_den = den;
        self.heads.fill(MAX_LIVE);
        self.reset_cursor(self.last_priority);
        for slot in 0..MAX_LIVE { if self.events[slot].active { self.insert(slot); } }
    }

    fn enqueue(&mut self, priority: i64) -> bool {
        if priority < 0 || priority > MAX_PRIORITY || priority < self.last_priority || self.live == MAX_LIVE { return false; }
        let Some(slot) = self.events.iter().position(|event| !event.active) else { return false; };
        self.events[slot] = Event { priority, id: self.next_id, next: MAX_LIVE, active: true };
        self.next_id += 1;
        self.live += 1;
        self.insert(slot);
        if self.live > 2 * self.buckets { self.resize(self.buckets * 2); }
        true
    }

    fn dequeue(&mut self) -> Option<Event> {
        if self.live == 0 { return None; }
        let mut bucket = self.last_bucket;
        loop {
            let slot = self.heads[bucket];
            if slot != MAX_LIVE && self.events[slot].priority * self.top_den < self.top_num {
                let event = self.events[slot];
                self.heads[bucket] = event.next;
                self.events[slot].active = false;
                self.live -= 1;
                self.last_bucket = bucket;
                self.last_priority = event.priority;
                if self.buckets > 2 && (self.live as i64) < self.buckets as i64 / 2 - 2 { self.resize(self.buckets / 2); }
                return Some(event);
            }
            bucket = (bucket + 1) % self.buckets;
            self.top_num += 2 * self.width_num;
            if bucket == self.last_bucket {
                let mut minimum = MAX_LIVE;
                for &head in &self.heads[..self.buckets] {
                    if head != MAX_LIVE && (minimum == MAX_LIVE || less(self.events[head], self.events[minimum])) { minimum = head; }
                }
                if minimum == MAX_LIVE { return None; }
                self.last_priority = self.events[minimum].priority;
                self.reset_cursor(self.last_priority);
                bucket = self.last_bucket;
            }
        }
    }
}

unsafe fn put_i64(output: *mut u8, word: usize, value: i64) {
    for (byte, part) in value.to_le_bytes().iter().enumerate() { *output.add(word * 8 + byte) = *part; }
}

#[no_mangle]
pub unsafe extern "C" fn calendar_queue(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count = values[0];
    if count < 0 || count as usize > MAX_OPS || length != 1 + 2 * count as usize { return -1; }
    let mut queue = Calendar::new();
    let mut trace = [0i64; 2 * MAX_OPS];
    let mut dequeued = 0usize;
    for step in 0..count as usize {
        let opcode = values[1 + 2 * step];
        let argument = values[2 + 2 * step];
        if opcode == 1 {
            if !queue.enqueue(argument) { return -1; }
        } else if opcode == 2 {
            if argument != 0 { return -1; }
            let Some(event) = queue.dequeue() else { return -1; };
            trace[2 * dequeued] = event.id;
            trace[2 * dequeued + 1] = event.priority;
            dequeued += 1;
        } else { return -1; }
    }
    let bytes = (1 + 2 * dequeued) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    put_i64(output, 0, dequeued as i64);
    for word in 0..2 * dequeued { put_i64(output, word + 1, trace[word]); }
    bytes as i64
}
