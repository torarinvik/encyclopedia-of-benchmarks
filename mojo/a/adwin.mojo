from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_LEVELS = 16
comptime BUCKET_CAPACITY = 6
comptime MIN_SUBWINDOW = 5

struct AdwinState:
    var sizes: List[Int64]
    var totals: List[Float64]
    var variances: List[Float64]
    var width: Int64
    var total: Float64
    var variance: Float64
    var bucket_count: Int64
    var delta: Float64

    fn __init__(out self, delta: Float64):
        self.sizes = List[Int64](length=MAX_LEVELS, fill=0)
        self.totals = List[Float64](length=MAX_LEVELS * BUCKET_CAPACITY, fill=0.0)
        self.variances = List[Float64](length=MAX_LEVELS * BUCKET_CAPACITY, fill=0.0)
        self.width = 0
        self.total = 0.0
        self.variance = 0.0
        self.bucket_count = 0
        self.delta = delta

    fn add_bucket(mut self, level: Int, total: Float64, variance: Float64):
        let slot = level * BUCKET_CAPACITY + Int(self.sizes[level])
        self.sizes[level] += 1
        self.totals[slot] = total
        self.variances[slot] = variance

    fn remove_oldest(mut self, level: Int, count: Int):
        let size = Int(self.sizes[level])
        for i in range(count, size):
            self.totals[level * BUCKET_CAPACITY + i - count] = self.totals[level * BUCKET_CAPACITY + i]
            self.variances[level * BUCKET_CAPACITY + i - count] = self.variances[level * BUCKET_CAPACITY + i]
        self.sizes[level] -= count

    fn compress(mut self):
        for level in range(MAX_LEVELS - 1):
            if self.sizes[level] <= 5:
                continue
            let bucket_size = Float64(1 << level)
            let ix0 = level * BUCKET_CAPACITY
            let mean_a = self.totals[ix0] / bucket_size
            let mean_b = self.totals[ix0 + 1] / bucket_size
            let difference = mean_a - mean_b
            let merged_var = self.variances[ix0] + self.variances[ix0 + 1] + bucket_size * bucket_size * difference * difference / (bucket_size + bucket_size)
            let merged_total = self.totals[ix0] + self.totals[ix0 + 1]
            self.add_bucket(level + 1, merged_total, merged_var)
            self.remove_oldest(level, 2)
            self.bucket_count -= 1

    fn insert(mut self, value: Float64):
        self.width += 1
        self.add_bucket(0, value, 0.0)
        self.bucket_count += 1
        if self.width > 1:
            let deviation = value - self.total / Float64(self.width - 1)
            self.variance += Float64(self.width - 1) * deviation * deviation / Float64(self.width)
        self.total += value
        self.compress()

    fn significant(self, old_width: Int64, recent_width: Int64, difference: Float64) -> Bool:
        let harmonic = 1.0 / Float64(old_width - MIN_SUBWINDOW + 1) + 1.0 / Float64(recent_width - MIN_SUBWINDOW + 1)
        let confidence = adwin_ln(2.0 * adwin_ln(Float64(self.width)) / self.delta)
        let window_variance = self.variance / Float64(self.width)
        let epsilon = adwin_sqrt(2.0 * harmonic * window_variance * confidence) + (2.0 / 3.0) * confidence * harmonic
        if difference < 0.0:
            return -difference > epsilon
        return difference > epsilon

    fn drop_oldest(mut self):
        var level = MAX_LEVELS - 1
        while level > 0 and self.sizes[level] == 0:
            level -= 1
        let size = Int64(1 << level)
        let slot = level * BUCKET_CAPACITY
        let bucket_total = self.totals[slot]
        self.width -= size
        self.total -= bucket_total
        if self.width > 0:
            let bucket_mean = bucket_total / Float64(size)
            let difference = bucket_mean - self.total / Float64(self.width)
            self.variance -= self.variances[slot] + Float64(size) * Float64(self.width) * difference * difference / Float64(size + self.width)
        else:
            self.variance = 0.0
        if self.variance < 0.0:
            self.variance = 0.0
        self.remove_oldest(level, 1)
        self.bucket_count -= 1

    fn detect_change(mut self) -> Int64:
        var changed: Int64 = 0
        var searching = True
        while searching and self.width >= 2 * MIN_SUBWINDOW:
            searching = False
            var stop = False
            var old_width: Int64 = 0
            var old_total: Float64 = 0.0
            var level = MAX_LEVELS - 1
            while level >= 0 and not stop:
                for bucket in range(Int(self.sizes[level])):
                    if level == 0 and bucket == Int(self.sizes[level]) - 1:
                        stop = True
                        break
                    let item_size = Int64(1 << level)
                    old_width += item_size
                    old_total += self.totals[level * BUCKET_CAPACITY + bucket]
                    let recent_width = self.width - old_width
                    let recent_total = self.total - old_total
                    if recent_width < MIN_SUBWINDOW:
                        stop = True
                        break
                    if old_width >= MIN_SUBWINDOW and self.significant(old_width, recent_width, old_total / Float64(old_width) - recent_total / Float64(recent_width)):
                        changed = 1
                        searching = True
                        self.drop_oldest()
                        stop = True
                        break
                level -= 1
        return changed

fn adwin_sqrt(value: Float64) -> Float64:
    if value <= 0.0:
        return 0.0
    var root = value
    if root < 1.0:
        root = 1.0
    for _ in range(80):
        root = 0.5 * (root + value / root)
    return root

fn adwin_ln(value0: Float64) -> Float64:
    var value = value0
    var exponent = 0
    while value >= 2.0:
        value *= 0.5
        exponent += 1
    let ratio = (value - 1.0) / (value + 1.0)
    let square = ratio * ratio
    var term = ratio
    var sum: Float64 = 0.0
    for i in range(40):
        sum += term / Float64(2 * i + 1)
        term *= square
    return 2.0 * sum + Float64(exponent) * 0.693147180559945309417232121458176568

fn adwin_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8):
        output[8 * index + b] = UInt8((bits >> (8 * b)) & 255)

@export("adwin")
fn adwin(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 258:
        return -1
    let count = input[0]
    let delta_value = input[1]
    if count < 1 or count > 256 or length != c_size_t(2 + count) or delta_value < 1 or delta_value > 100000000:
        return -1
    for i in range(count):
        if input[2 + i] < -1000000000 or input[2 + i] > 1000000000:
            return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16 * count):
        return -2
    var state = AdwinState(Float64(delta_value) / 1000000000.0)
    for i in range(count):
        state.insert(Float64(input[2 + i]) / 1000000000.0)
        let changed = state.detect_change()
        adwin_write_i64(output, Int(2 * i), changed)
        adwin_write_i64(output, Int(2 * i + 1), state.width)
    return 2 * count
