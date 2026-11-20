from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_K = 3
comptime MAX_INPUT = 1557
comptime MAX_RECORDS = 372
comptime PERIODS = 9
comptime BIT_WORDS = 39
comptime MAX_OUTPUT = 11912

@fieldwise_init
struct KrRecord(Copyable):
    var start: Int
    var finish: Int
    var period: Int
    var errors: Int

struct KrState:
    var word: InlineArray[Int, MAX_N]
    var starts: InlineArray[Int, MAX_N]
    var ends: InlineArray[Int, MAX_N]
    var copies: InlineArray[Int, MAX_N]
    var records: InlineArray[KrRecord, MAX_RECORDS]
    var known: InlineArray[UInt64, BIT_WORDS]
    var generated: InlineArray[UInt64, BIT_WORDS]
    var n: Int
    var budget: Int
    var factor_count: Int
    var record_count: Int

    fn __init__(out self):
        self.word = InlineArray[Int, MAX_N](fill=0)
        self.starts = InlineArray[Int, MAX_N](fill=0)
        self.ends = InlineArray[Int, MAX_N](fill=0)
        self.copies = InlineArray[Int, MAX_N](fill=0)
        self.records = InlineArray[KrRecord, MAX_RECORDS](fill=KrRecord(0, 0, 0, 0))
        self.known = InlineArray[UInt64, BIT_WORDS](fill=0)
        self.generated = InlineArray[UInt64, BIT_WORDS](fill=0)
        self.n = 0
        self.budget = 0
        self.factor_count = 0
        self.record_count = 0

fn kr_bit(start: Int, finish: Int, period: Int) -> Int:
    return (start * (MAX_N + 1) + finish) * PERIODS + period

fn kr_marked(bits: InlineArray[UInt64, BIT_WORDS], bit: Int) -> Bool:
    return (bits[bit // 64] & (UInt64(1) << UInt64(bit % 64))) != 0

fn kr_lce(word: InlineArray[Int, MAX_N], n: Int, left: Int, right: Int) -> Int:
    var length = 0
    while left + length < n and right + length < n and word[left + length] == word[right + length]:
        length += 1
    return length

fn kr_less(a: KrRecord, b: KrRecord) -> Bool:
    if a.start != b.start: return a.start < b.start
    if a.finish != b.finish: return a.finish < b.finish
    if a.period != b.period: return a.period < b.period
    return a.errors < b.errors

fn kr_add(mut state: KrState, record: KrRecord, is_generated: Bool):
    let bit = kr_bit(record.start, record.finish, record.period)
    if kr_marked(state.known, bit): return
    state.known[bit // 64] |= UInt64(1) << UInt64(bit % 64)
    if is_generated: state.generated[bit // 64] |= UInt64(1) << UInt64(bit % 64)
    var at = state.record_count
    while at > 0 and kr_less(record, state.records[at - 1]):
        state.records[at] = state.records[at - 1]
        at -= 1
    state.records[at] = record
    state.record_count += 1

fn kr_factors_valid(word: InlineArray[Int, MAX_N], starts: InlineArray[Int, MAX_N],
                    ends: InlineArray[Int, MAX_N], copies: InlineArray[Int, MAX_N],
                    n: Int, factor_count: Int) -> Bool:
    if factor_count <= 0 or factor_count > n: return False
    var position = 0
    for f in range(factor_count):
        let a = starts[f]
        let b = ends[f]
        let c = copies[f]
        if a != position or a < 0 or b <= a or b > n: return False
        if f == 0:
            if a != 0 or b != 1 or c != -1: return False
            position = b
            continue
        var longest = 0
        for earlier in range(a):
            let matched = kr_lce(word, n, earlier, a)
            if matched > longest: longest = matched
        var expected_end = a + longest + 1
        if expected_end > n: expected_end = n
        if b != expected_end: return False
        let prefix = b - a - 1
        if prefix == 0:
            if c != -1: return False
        elif c < 0 or c >= a or kr_lce(word, n, c, a) != prefix:
            return False
        position = b
    return position == n

fn kr_mismatches(word: InlineArray[Int, MAX_N], start: Int, finish: Int, period: Int) -> Int:
    var errors = 0
    for i in range(start, finish - period):
        if word[i] != word[i + period]: errors += 1
    return errors

fn kr_seed_valid(word: InlineArray[Int, MAX_N], n: Int, budget: Int, record: KrRecord) -> Bool:
    let a = record.start
    let b = record.finish
    let p = record.period
    if a < 0 or a >= b or b > n or p < 1 or p > n // 2 or b - a < 2 * p: return False
    let errors = kr_mismatches(word, a, b, p)
    if errors != record.errors or errors > budget: return False
    if a > 0:
        var left_error = 0
        if word[a - 1] != word[a + p - 1]: left_error = 1
        if errors + left_error <= budget: return False
    if b < n:
        var right_error = 0
        if word[b - p] != word[b]: right_error = 1
        if errors + right_error <= budget: return False
    return True

fn kr_propagate(mut state: KrState):
    for f in range(state.factor_count):
        let a = state.starts[f]
        let b = state.ends[f]
        let c = state.copies[f]
        let copied = b - a - 1
        if copied <= 0: continue
        let delta = a - c
        let copy_end = c + copied
        for target in range(a + 1, b - 1):
            let source_start = target - delta
            var index = 0
            while index < state.record_count and state.records[index].start < source_start:
                index += 1
            while index < state.record_count and state.records[index].start == source_start:
                let source = state.records[index]
                if source.finish > copy_end: break
                let target_end = source.finish + delta
                if target_end <= b - 2:
                    kr_add(mut state, KrRecord(target, target_end, source.period, source.errors), True)
                index += 1

fn kr_put(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("k_repetition_within_factor_copy_propagation")
fn k_repetition_within_factor_copy_propagation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    if input[0] < 1 or input[0] > Int64(MAX_N) or input[1] < 0 or input[1] > Int64(MAX_K): return -1
    let n = Int(input[0])
    let budget = Int(input[1])
    if length < c_size_t(n + 3): return -1
    var state = KrState()
    state.n = n
    state.budget = budget
    var cursor = 2
    for i in range(n):
        let symbol = input[cursor]
        if symbol < 0 or symbol > 5: return -1
        state.word[i] = Int(symbol)
        cursor += 1
    for i in range(n - 1):
        if state.word[i] == state.word[n - 1]: return -1
    if cursor >= Int(length) or input[cursor] < 1 or input[cursor] > Int64(n): return -1
    state.factor_count = Int(input[cursor])
    cursor += 1
    if cursor + 3 * state.factor_count >= Int(length): return -1
    for i in range(state.factor_count):
        let a = input[cursor]
        let b = input[cursor + 1]
        let c = input[cursor + 2]
        if a < 0 or a > Int64(n) or b < 0 or b > Int64(n) or c < -1 or c > Int64(n): return -1
        state.starts[i] = Int(a)
        state.ends[i] = Int(b)
        state.copies[i] = Int(c)
        cursor += 3
    if cursor >= Int(length) or not kr_factors_valid(state.word, state.starts, state.ends, state.copies, n, state.factor_count): return -1
    let seed_count_value = input[cursor]
    cursor += 1
    if seed_count_value < 0 or seed_count_value > Int64(MAX_RECORDS) or cursor + 4 * Int(seed_count_value) != Int(length): return -1
    for _ in range(Int(seed_count_value)):
        let a = input[cursor]
        let b = input[cursor + 1]
        let p = input[cursor + 2]
        let e = input[cursor + 3]
        if a < 0 or a > Int64(n) or b < 0 or b > Int64(n) or p < 0 or p > Int64(n) or e < 0 or e > Int64(MAX_K): return -1
        let seed = KrRecord(Int(a), Int(b), Int(p), Int(e))
        if not kr_seed_valid(state.word, n, budget, seed): return -1
        kr_add(mut state, seed, False)
        cursor += 4
    kr_propagate(mut state)
    var count = 0
    for i in range(state.record_count):
        let r = state.records[i]
        if kr_marked(state.generated, kr_bit(r.start, r.finish, r.period)): count += 1
    let written = 8 + count * 32
    if written > MAX_OUTPUT: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(written): return -2
    kr_put(output, 0, Int64(count))
    var offset = 8
    for i in range(state.record_count):
        let r = state.records[i]
        if not kr_marked(state.generated, kr_bit(r.start, r.finish, r.period)): continue
        kr_put(output, offset, Int64(r.start)); offset += 8
        kr_put(output, offset, Int64(r.finish)); offset += 8
        kr_put(output, offset, Int64(r.period)); offset += 8
        kr_put(output, offset, Int64(r.errors)); offset += 8
    return Int64(written)
