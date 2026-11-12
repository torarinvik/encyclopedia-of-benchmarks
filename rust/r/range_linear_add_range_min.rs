const MAX_LENGTH: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT: usize = 387;
const BLOCK_WIDTH: usize = 8;
const MAX_BLOCKS: usize = 8;
const CHECKSUM_OFFSET: i64 = 8_000_000;

struct State {
    data: [i64; MAX_LENGTH],
    hull_x: [i64; MAX_LENGTH],
    hull_y: [i64; MAX_LENGTH],
    hull_count: [usize; MAX_BLOCKS],
    lazy_slope: [i64; MAX_BLOCKS],
    lazy_intercept: [i64; MAX_BLOCKS],
    n: usize,
}

impl State {
    fn block_end(&self, block: usize) -> usize { ((block + 1) * BLOCK_WIDTH).min(self.n) }

    fn rebuild(&mut self, block: usize) {
        let base = block * BLOCK_WIDTH;
        let mut size = 0;
        for x in base..self.block_end(block) {
            while size >= 2 {
                let p = base + size - 2;
                let q = base + size - 1;
                let cross = (self.hull_x[q] - self.hull_x[p]) * (self.data[x] - self.hull_y[p])
                    - (self.hull_y[q] - self.hull_y[p]) * (x as i64 - self.hull_x[p]);
                if cross > 0 { break; }
                size -= 1;
            }
            self.hull_x[base + size] = x as i64;
            self.hull_y[base + size] = self.data[x];
            size += 1;
        }
        self.hull_count[block] = size;
    }

    fn push(&mut self, block: usize) {
        let start = block * BLOCK_WIDTH;
        for i in start..self.block_end(block) {
            self.data[i] += self.lazy_slope[block] * i as i64 + self.lazy_intercept[block];
        }
        self.lazy_slope[block] = 0;
        self.lazy_intercept[block] = 0;
    }

    fn block_min(&self, block: usize) -> i64 {
        let base = block * BLOCK_WIDTH;
        let mut low = 0;
        let mut high = self.hull_count[block] - 1;
        while low < high {
            let mid = low + (high - low) / 2;
            let left = self.hull_y[base + mid] + self.lazy_slope[block] * self.hull_x[base + mid];
            let right = self.hull_y[base + mid + 1]
                + self.lazy_slope[block] * self.hull_x[base + mid + 1];
            if left <= right { high = mid; } else { low = mid + 1; }
        }
        self.hull_y[base + low] + self.lazy_slope[block] * self.hull_x[base + low]
            + self.lazy_intercept[block]
    }

    fn update(&mut self, left: usize, right: usize, slope: i64, intercept: i64) {
        let mut position = left;
        while position < right {
            let block = position / BLOCK_WIDTH;
            let start = block * BLOCK_WIDTH;
            let end = self.block_end(block);
            if position == start && end <= right {
                self.lazy_slope[block] += slope;
                self.lazy_intercept[block] += intercept;
                position = end;
            } else {
                self.push(block);
                let stop = end.min(right);
                for i in position..stop { self.data[i] += slope * i as i64 + intercept; }
                self.rebuild(block);
                position = stop;
            }
        }
    }

    fn query(&self, left: usize, right: usize) -> i64 {
        let mut position = left;
        let mut minimum = i64::MAX;
        while position < right {
            let block = position / BLOCK_WIDTH;
            let start = block * BLOCK_WIDTH;
            let end = self.block_end(block);
            if position == start && end <= right {
                minimum = minimum.min(self.block_min(block));
                position = end;
            } else {
                let stop = end.min(right);
                for i in position..stop {
                    minimum = minimum.min(self.data[i] + self.lazy_slope[block] * i as i64
                                           + self.lazy_intercept[block]);
                }
                position = stop;
            }
        }
        minimum
    }
}

#[no_mangle]
pub unsafe extern "C" fn range_linear_add_range_min_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_LENGTH as i64).contains(&input[0]) ||
        !(1..=MAX_OPERATIONS as i64).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let q = input[1] as usize;
    if length < n + 2 { return -1; }
    let mut state = State {
        data: [0; MAX_LENGTH], hull_x: [0; MAX_LENGTH], hull_y: [0; MAX_LENGTH],
        hull_count: [0; MAX_BLOCKS], lazy_slope: [0; MAX_BLOCKS],
        lazy_intercept: [0; MAX_BLOCKS], n,
    };
    for i in 0..n {
        if !(-1_000_000..=1_000_000).contains(&input[i + 2]) { return -1; }
        state.data[i] = input[i + 2];
    }
    for block in 0..(n + BLOCK_WIDTH - 1) / BLOCK_WIDTH { state.rebuild(block); }
    let mut cursor = n + 2;
    let mut checksum = 0_i64;
    for operation in 0..q {
        if cursor >= length { return -1; }
        let opcode = input[cursor]; cursor += 1;
        if opcode == 0 {
            if cursor + 4 > length { return -1; }
            let (left, right, slope, intercept) =
                (input[cursor], input[cursor + 1], input[cursor + 2], input[cursor + 3]);
            cursor += 4;
            if left < 0 || left >= right || right > n as i64 || !(-99..=99).contains(&slope) ||
                !(-100_000..=100_000).contains(&intercept) { return -1; }
            state.update(left as usize, right as usize, slope, intercept);
        } else if opcode == 1 {
            if cursor + 2 > length { return -1; }
            let (left, right) = (input[cursor], input[cursor + 1]); cursor += 2;
            if left < 0 || left >= right || right > n as i64 { return -1; }
            checksum += (operation as i64 + 1) * (state.query(left as usize, right as usize) + CHECKSUM_OFFSET);
        } else { return -1; }
    }
    if cursor == length { checksum } else { -1 }
}
