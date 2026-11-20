from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn nn_matches(mask: UInt32, length: Int, clues: InlineArray[Int, 128], start: Int, count: Int) -> Bool:
    var found = 0
    var run = 0
    for bit in range(length):
        if ((mask >> bit) & 1) != 0:
            run += 1
        elif run != 0:
            if found >= count or clues[start + found] != run: return False
            found += 1
            run = 0
    if run != 0:
        if found >= count or clues[start + found] != run: return False
        found += 1
    return found == count

fn nn_has(domains: InlineArray[UInt64, 64], line: Int, mask: Int) -> Bool:
    return (domains[line * 4 + mask // 64] & (UInt64(1) << (mask % 64))) != 0

fn nn_add(inout domains: InlineArray[UInt64, 64], line: Int, mask: Int) -> None:
    domains[line * 4 + mask // 64] |= UInt64(1) << (mask % 64)

fn nn_count(domains: InlineArray[UInt64, 64], line: Int, length: Int) -> Int:
    var total = 0
    for mask in range(1 << length):
        if nn_has(domains, line, mask): total += 1
    return total

fn nn_filter(inout domains: InlineArray[UInt64, 64], line: Int, length: Int, pos: Int,
             allow_zero: Bool, allow_one: Bool) -> Bool:
    var changed = False
    for mask in range(1 << length):
        if not nn_has(domains, line, mask): continue
        let one = ((mask >> pos) & 1) != 0
        if (one and allow_one) or (not one and allow_zero): continue
        domains[line * 4 + mask // 64] &= ~(UInt64(1) << (mask % 64))
        changed = True
    return changed

fn nn_support(domains: InlineArray[UInt64, 64], line: Int, length: Int, pos: Int,
              inout zero: Bool, inout one: Bool) -> Bool:
    zero = False
    one = False
    for mask in range(1 << length):
        if not nn_has(domains, line, mask): continue
        if ((mask >> pos) & 1) != 0: one = True
        else: zero = True
    return zero or one

fn nn_propagate(inout domains: InlineArray[UInt64, 64], height: Int, width: Int) -> Bool:
    var changed = True
    while changed:
        changed = False
        for row in range(height):
            for col in range(width):
                var rz = False
                var ro = False
                var cz = False
                var co = False
                if not nn_support(domains, row, width, col, inout rz, inout ro) or
                   not nn_support(domains, height + col, height, row, inout cz, inout co): return False
                if nn_filter(inout domains, row, width, col, cz, co): changed = True
                if nn_filter(inout domains, height + col, height, row, rz, ro): changed = True
                if nn_count(domains, row, width) == 0 or nn_count(domains, height + col, height) == 0: return False
    return True

fn nn_search(inout domains: InlineArray[UInt64, 64], height: Int, width: Int) -> Bool:
    if not nn_propagate(inout domains, height, width): return False
    var branch = height
    for row in range(height):
        if nn_count(domains, row, width) > 1:
            branch = row
            break
    if branch == height: return True
    for mask in range(1 << width):
        if not nn_has(domains, branch, mask): continue
        var trial = domains
        for word in range(4): trial[branch * 4 + word] = 0
        nn_add(inout trial, branch, mask)
        if nn_search(inout trial, height, width):
            domains = trial
            return True
    return False

fn nonogram_line_domain_solver_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) -> Int64:
    if input.is_null() or length < 2 or length > 82: return -1
    let h_value = input[0]
    let w_value = input[1]
    if h_value < 1 or h_value > 8 or w_value < 1 or w_value > 8: return -1
    let height = Int(h_value)
    let width = Int(w_value)
    if length != c_size_t(2 + 5 * height + 5 * width): return -1
    var clues = InlineArray[Int, 128](fill=0)
    var counts = InlineArray[Int, 16](fill=0)
    var offset = 2
    for group in range(2):
        let lines = height if group == 0 else width
        let line_length = width if group == 0 else height
        for line in range(lines):
            let index = line if group == 0 else height + line
            let raw_count = input[offset]
            offset += 1
            if raw_count < 0 or raw_count > 4: return -1
            counts[index] = Int(raw_count)
            var needed = Int(raw_count) - (1 if raw_count > 0 else 0)
            for run in range(4):
                let value = input[offset]
                offset += 1
                if run < counts[index]:
                    if value <= 0 or value > line_length: return -1
                    clues[index * 8 + run] = Int(value)
                    needed += Int(value)
                elif value != 0: return -1
            if needed > line_length: return -1
    var row_total = 0
    var col_total = 0
    for row in range(height):
        for run in range(counts[row]): row_total += clues[row * 8 + run]
    for col in range(width):
        let line = height + col
        for run in range(counts[line]): col_total += clues[line * 8 + run]
    if row_total != col_total: return -1
    var domains = InlineArray[UInt64, 64](fill=0)
    for row in range(height):
        for mask in range(1 << width):
            if nn_matches(UInt32(mask), width, clues, row * 8, counts[row]): nn_add(inout domains, row, mask)
        if nn_count(domains, row, width) == 0: return -1
    for col in range(width):
        let line = height + col
        for mask in range(1 << height):
            if nn_matches(UInt32(mask), height, clues, line * 8, counts[line]): nn_add(inout domains, line, mask)
        if nn_count(domains, line, height) == 0: return -1
    if not nn_search(inout domains, height, width): return -1
    let required = height * width
    if output.is_null() or output_capacity < c_size_t(required): return -2
    for row in range(height):
        var mask = 0
        while mask < (1 << width) and not nn_has(domains, row, mask): mask += 1
        for col in range(width): output[row * width + col] = UInt8((mask >> col) & 1)
    return Int64(required)

@export("nonogram_line_domain_solver")
fn nonogram_line_domain_solver(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    return nonogram_line_domain_solver_impl(input, length, output, output_capacity)
