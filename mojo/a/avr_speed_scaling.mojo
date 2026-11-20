from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime AVR_MAX_JOBS = 8
comptime AVR_MAX_TIME = 8
comptime AVR_MAX_INPUT = 25
comptime AVR_MAX_OUTPUT_VALUES = 79
comptime AVR_MAX_OUTPUT_BYTES = 632
comptime AVR_DENSITY_SCALE = 840

fn avr_gcd(a0: Int64, b0: Int64) -> Int64:
    var a = a0
    var b = b0
    while b != 0:
        let r = a % b
        a = b
        b = r
    if a < 0: return -a
    return a

fn avr_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("avr_speed_scaling")
fn avr_speed_scaling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(4) or length > c_size_t(AVR_MAX_INPUT): return -1
    let jobs_value = input[0]
    if jobs_value < 1 or jobs_value > Int64(AVR_MAX_JOBS): return -1
    let jobs = Int(jobs_value)
    if length != c_size_t(1 + 3 * jobs): return -1

    var release = InlineArray[Int64, AVR_MAX_JOBS](fill=0)
    var deadline = InlineArray[Int64, AVR_MAX_JOBS](fill=0)
    var remaining = InlineArray[Int64, AVR_MAX_JOBS](fill=0)
    var changes = InlineArray[Int64, AVR_MAX_TIME + 1](fill=0)
    var points = InlineArray[UInt8, AVR_MAX_TIME + 1](fill=0)
    var finish_num = InlineArray[Int64, AVR_MAX_JOBS](fill=0)
    var finish_den = InlineArray[Int64, AVR_MAX_JOBS](fill=0)
    var finished = InlineArray[UInt8, AVR_MAX_JOBS](fill=0)

    for j in range(jobs):
        let r = input[1 + 3 * j]
        let d = input[2 + 3 * j]
        let w = input[3 + 3 * j]
        if r < 0 or r >= d or d > Int64(AVR_MAX_TIME) or w < 1 or w > 8: return -1
        release[j] = r
        deadline[j] = d
        let scaled_density = w * (Int64(AVR_DENSITY_SCALE) // (d - r))
        changes[Int(r)] += scaled_density
        changes[Int(d)] -= scaled_density
        points[Int(r)] = 1
        points[Int(d)] = 1
        remaining[j] = w * Int64(AVR_DENSITY_SCALE)

    var values = InlineArray[Int64, AVR_MAX_OUTPUT_VALUES](fill=0)
    var segment_count = 0
    var energy_scaled: Int64 = 0
    var speed_scaled: Int64 = 0
    for start in range(AVR_MAX_TIME):
        speed_scaled += changes[start]
        if points[start] == 0: continue
        var end = start + 1
        while end <= AVR_MAX_TIME and points[end] == 0: end += 1
        if end > AVR_MAX_TIME or speed_scaled <= 0: continue

        energy_scaled += speed_scaled * speed_scaled * speed_scaled * Int64(end - start)
        let speed_gcd = avr_gcd(speed_scaled, Int64(AVR_DENSITY_SCALE))
        let speed_num = speed_scaled // speed_gcd
        let speed_den = Int64(AVR_DENSITY_SCALE) // speed_gcd
        if segment_count > 0:
            let last = 3 + 4 * (segment_count - 1)
            if values[last + 1] == Int64(start) and values[last + 2] == speed_num and values[last + 3] == speed_den:
                values[last + 1] = Int64(end)
            else:
                let at = 3 + 4 * segment_count
                segment_count += 1
                values[at] = Int64(start)
                values[at + 1] = Int64(end)
                values[at + 2] = speed_num
                values[at + 3] = speed_den
        else:
            let at = 3 + 4 * segment_count
            segment_count += 1
            values[at] = Int64(start)
            values[at + 1] = Int64(end)
            values[at + 2] = speed_num
            values[at + 3] = speed_den

        var cursor_scaled = Int64(start) * speed_scaled
        let end_scaled = Int64(end) * speed_scaled
        while cursor_scaled < end_scaled:
            var selected = jobs
            for j in range(jobs):
                if finished[j] != 0 or remaining[j] <= 0 or release[j] > Int64(start) or deadline[j] <= Int64(start): continue
                if selected == jobs or deadline[j] < deadline[selected]: selected = j
            if selected == jobs: break
            if cursor_scaled + remaining[selected] <= end_scaled:
                cursor_scaled += remaining[selected]
                remaining[selected] = 0
                let common = avr_gcd(cursor_scaled, speed_scaled)
                finish_num[selected] = cursor_scaled // common
                finish_den[selected] = speed_scaled // common
                finished[selected] = 1
            else:
                remaining[selected] -= end_scaled - cursor_scaled
                cursor_scaled = end_scaled

    for j in range(jobs):
        if finished[j] == 0: return -1
    let energy_denominator = Int64(AVR_DENSITY_SCALE * AVR_DENSITY_SCALE * AVR_DENSITY_SCALE)
    let energy_gcd = avr_gcd(energy_scaled, energy_denominator)
    let segment_end = 3 + 4 * segment_count
    values[0] = Int64(segment_count)
    values[1] = energy_scaled // energy_gcd
    values[2] = energy_denominator // energy_gcd
    var output_values = segment_end
    for j in range(jobs):
        values[output_values] = finish_num[j]
        output_values += 1
        values[output_values] = finish_den[j]
        output_values += 1

    let output_bytes = 8 * output_values
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for i in range(output_values):
        avr_store_i64(output, 8 * i, values[i])
    return Int64(output_bytes)
