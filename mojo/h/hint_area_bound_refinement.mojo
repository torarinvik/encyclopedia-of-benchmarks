# Independently authored HINT integer profile. Source attribution and GPL notice:
# benchmarks/h/hint_area_bound_refinement/README.md and LICENSE.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn hint_error(flh: Int, fll: Int, frh: Int, frl: Int, width: Int) -> Int:
    let correction = max(0, (fll - frh) * (width - 2))
    return (flh - frh + fll - frl) * (width - 1) - correction

@export("hint_area_bound_refinement")
fn hint_area_bound_refinement(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let xb = input[0]
    let yb = input[1]
    let requested = input[2]
    if xb < 1 or xb > 8 or yb < 1 or yb > 8 or xb + yb > 16: return -1
    let scx = 1 << Int(xb)
    let scy = 1 << Int(yb)
    if requested < 0 or requested > 64 or requested > scx - 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 40: return -2
    var lower = 0
    var upper = scx * scy - 1
    var lo_area = InlineArray[Int, 65](fill=0)
    var hi_area = InlineArray[Int, 65](fill=0)
    var widths = InlineArray[Int, 65](fill=0)
    var xleft = InlineArray[Int, 65](fill=0)
    var xright = InlineArray[Int, 65](fill=0)
    var fl_low = InlineArray[Int, 65](fill=0)
    var fl_high = InlineArray[Int, 65](fill=0)
    var fr_low = InlineArray[Int, 65](fill=0)
    var fr_high = InlineArray[Int, 65](fill=0)
    var errors = InlineArray[Int, 130](fill=0)
    var indices = InlineArray[Int, 130](fill=0)
    hi_area[0] = upper
    widths[0] = scx
    xright[0] = scx
    fl_low[0] = scy
    fl_high[0] = scy
    errors[0] = upper
    var tail = 0
    var step = 0
    while step < Int(requested) and step <= tail:
        let left = indices[step]
        let right = step + 1
        let parent_low = lo_area[left]
        let parent_high = hi_area[left]
        widths[left] //= 2
        widths[right] = widths[left]
        xright[right] = xright[left]
        xright[left] = xleft[left] + widths[left]
        xleft[right] = xright[left]
        fr_low[right] = fr_low[left]
        fr_high[right] = fr_high[left]
        let numerator = scy * (scx - xright[left])
        let denominator = scx + xright[left]
        let below = numerator // denominator
        let above = below + (1 if below * denominator != numerator else 0)
        fr_low[left] = below
        fr_high[left] = above
        fl_low[right] = below
        fl_high[right] = above
        let left_error = hint_error(fl_high[left], fl_low[left], fr_high[left], fr_low[left], widths[left])
        let right_error = hint_error(fl_high[right], fl_low[right], fr_high[right], fr_low[right], widths[right])
        let slot = 2 if left_error < right_error else 1
        errors[tail + slot] = left_error
        indices[tail + slot] = left
        errors[tail + 3 - slot] = right_error
        indices[tail + 3 - slot] = right
        tail += 2 if errors[tail + 2] != 0 else 1
        lo_area[left] = fr_low[left] * widths[left]
        lo_area[right] = fr_low[right] * widths[right]
        hi_area[left] = fl_high[left] * widths[left]
        hi_area[right] = fl_high[right] * widths[right]
        lower += lo_area[left] + lo_area[right] - parent_low
        upper += hi_area[left] + hi_area[right] - parent_high
        step += 1
    let status = 1 if step > tail else 0
    let result = InlineArray[Int, 5](status, step, lower, upper, upper - lower)
    for i in range(5):
        let bits = bitcast[UInt64](Int64(result[i]))
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return 40
