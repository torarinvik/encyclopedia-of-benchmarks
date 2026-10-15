const MAX_SAMPLES: usize = 256;
const MAX_LEVELS: usize = 16;
const MAX_BUCKETS: usize = 5;
const BUCKET_CAPACITY: usize = MAX_BUCKETS + 1;
const MIN_SUBWINDOW: i64 = 5;
const INPUT_SCALE: f64 = 1_000_000_000.0;

struct Adwin {
    sizes: [usize; MAX_LEVELS],
    totals: [[f64; BUCKET_CAPACITY]; MAX_LEVELS],
    variances: [[f64; BUCKET_CAPACITY]; MAX_LEVELS],
    width: i64,
    total: f64,
    variance: f64,
    bucket_count: usize,
    delta: f64,
}

impl Adwin {
    fn new(delta: f64) -> Self {
        Self {
            sizes: [0; MAX_LEVELS],
            totals: [[0.0; BUCKET_CAPACITY]; MAX_LEVELS],
            variances: [[0.0; BUCKET_CAPACITY]; MAX_LEVELS],
            width: 0, total: 0.0, variance: 0.0, bucket_count: 0, delta,
        }
    }

    fn sqrt(value: f64) -> f64 {
        if value <= 0.0 { return 0.0; }
        let mut root = if value > 1.0 { value } else { 1.0 };
        for _ in 0..80 { root = 0.5 * (root + value / root); }
        root
    }

    fn ln(mut value: f64) -> f64 {
        let mut exponent = 0;
        while value >= 2.0 { value *= 0.5; exponent += 1; }
        let ratio = (value - 1.0) / (value + 1.0);
        let square = ratio * ratio;
        let mut term = ratio;
        let mut sum = 0.0;
        for iteration in 0..40 { sum += term / (2 * iteration + 1) as f64; term *= square; }
        2.0 * sum + exponent as f64 * 0.693147180559945309417232121458176568
    }

    fn add_bucket(&mut self, level: usize, total: f64, variance: f64) {
        let slot = self.sizes[level];
        self.totals[level][slot] = total;
        self.variances[level][slot] = variance;
        self.sizes[level] += 1;
    }

    fn remove_oldest(&mut self, level: usize, count: usize) {
        let old_size = self.sizes[level];
        for i in count..old_size {
            self.totals[level][i - count] = self.totals[level][i];
            self.variances[level][i - count] = self.variances[level][i];
        }
        self.sizes[level] -= count;
    }

    fn compress(&mut self) {
        for level in 0..MAX_LEVELS - 1 {
            if self.sizes[level] <= MAX_BUCKETS { break; }
            let size = (1usize << level) as f64;
            let first_mean = self.totals[level][0] / size;
            let second_mean = self.totals[level][1] / size;
            let difference = first_mean - second_mean;
            let merged_variance = self.variances[level][0] + self.variances[level][1] +
                size * size * difference * difference / (size + size);
            self.add_bucket(level + 1, self.totals[level][0] + self.totals[level][1], merged_variance);
            self.remove_oldest(level, 2);
            self.bucket_count -= 1;
        }
    }

    fn insert(&mut self, value: f64) {
        self.width += 1;
        self.add_bucket(0, value, 0.0);
        self.bucket_count += 1;
        if self.width > 1 {
            let deviation = value - self.total / (self.width - 1) as f64;
            self.variance += (self.width - 1) as f64 * deviation * deviation / self.width as f64;
        }
        self.total += value;
        self.compress();
    }

    fn significant(&self, old_width: i64, recent_width: i64, difference: f64) -> bool {
        let harmonic = 1.0 / (old_width - MIN_SUBWINDOW + 1) as f64 +
            1.0 / (recent_width - MIN_SUBWINDOW + 1) as f64;
        let confidence = Self::ln(2.0 * Self::ln(self.width as f64) / self.delta);
        let window_variance = self.variance / self.width as f64;
        let epsilon = Self::sqrt(2.0 * harmonic * window_variance * confidence) +
            2.0 / 3.0 * confidence * harmonic;
        (if difference < 0.0 { -difference } else { difference }) > epsilon
    }

    fn drop_oldest(&mut self) {
        let mut level = MAX_LEVELS - 1;
        while level > 0 && self.sizes[level] == 0 { level -= 1; }
        let size = (1usize << level) as i64;
        let bucket_total = self.totals[level][0];
        self.width -= size;
        self.total -= bucket_total;
        if self.width > 0 {
            let bucket_mean = bucket_total / size as f64;
            let difference = bucket_mean - self.total / self.width as f64;
            self.variance -= self.variances[level][0] + size as f64 * self.width as f64 *
                difference * difference / (size + self.width) as f64;
        } else {
            self.variance = 0.0;
        }
        if self.variance < 0.0 { self.variance = 0.0; }
        self.remove_oldest(level, 1);
        self.bucket_count -= 1;
    }

    fn detect_change(&mut self) -> bool {
        let mut changed = false;
        let mut searching = true;
        while searching && self.width >= 2 * MIN_SUBWINDOW {
            searching = false;
            let mut stop = false;
            let mut old_width = 0i64;
            let mut old_total = 0.0;
            for level in (0..MAX_LEVELS).rev() {
                for bucket in 0..self.sizes[level] {
                    if level == 0 && bucket == self.sizes[level] - 1 { stop = true; break; }
                    old_width += (1usize << level) as i64;
                    old_total += self.totals[level][bucket];
                    let recent_width = self.width - old_width;
                    let recent_total = self.total - old_total;
                    if recent_width < MIN_SUBWINDOW { stop = true; break; }
                    if old_width >= MIN_SUBWINDOW && self.significant(
                        old_width, recent_width,
                        old_total / old_width as f64 - recent_total / recent_width as f64,
                    ) {
                        changed = true;
                        searching = true;
                        self.drop_oldest();
                        stop = true;
                        break;
                    }
                }
                if stop { break; }
            }
        }
        changed
    }
}

#[no_mangle]
pub unsafe extern "C" fn adwin(input: *const i64, length: usize,
                                 output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 2 + MAX_SAMPLES { return -1; }
    let sample_count_value = *input;
    let delta_value = *input.add(1);
    if sample_count_value < 1 || sample_count_value > MAX_SAMPLES as i64 ||
        length != 2 + sample_count_value as usize || delta_value < 1 || delta_value > 100_000_000 { return -1; }
    let sample_count = sample_count_value as usize;
    for i in 0..sample_count {
        let value = *input.add(2 + i);
        if !(-1_000_000_000..=1_000_000_000).contains(&value) { return -1; }
    }
    if output.is_null() || output_capacity < 16 * sample_count { return -2; }

    let mut state = Adwin::new(delta_value as f64 / INPUT_SCALE);
    for i in 0..sample_count {
        state.insert(*input.add(2 + i) as f64 / INPUT_SCALE);
        let flag = if state.detect_change() { 1i64 } else { 0i64 };
        for (word, value) in [flag, state.width].iter().enumerate() {
            let bits = *value as u64;
            for byte in 0..8 { *output.add(16 * i + 8 * word + byte) = (bits >> (8 * byte)) as u8; }
        }
    }
    (2 * sample_count) as i64
}
