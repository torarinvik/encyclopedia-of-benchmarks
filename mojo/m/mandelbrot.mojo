from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mb_mul(a: Float64, b: Float64) -> Float64:
    var result: Float64 = a * b
    return result
fn mb_add(a: Float64, b: Float64) -> Float64:
    var result: Float64 = a + b
    return result
fn mb_sub(a: Float64, b: Float64) -> Float64:
    var result: Float64 = a - b
    return result
fn mb_div(a: Float64, b: Float64) -> Float64:
    var result: Float64 = a / b
    return result
fn mb_coord(center: Float64, position: Int64, dimension: Int64, span: Float64) -> Float64:
    let normalized = mb_div(Float64(position), Float64(dimension))
    let centered = mb_sub(normalized, 0.5)
    let offset = mb_mul(centered, span)
    return mb_add(center, offset)

@export("mandelbrot")
fn mandelbrot(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 6: return -1
    let width = v[0]; let height = v[1]; let cxq = v[2]; let cyq = v[3]; let fwq = v[4]; let max_step = v[5]
    if width < 1 or width > 16 or height < 1 or height > 16 or cxq < -64 or cxq > 64 or cyq < -64 or cyq > 64 or fwq < 1 or fwq > 64 or max_step < 2 or max_step > 64: return -1
    let cx = Float64(cxq) / 16.0; let cy = Float64(cyq) / 16.0; let fw = Float64(fwq) / 16.0
    let fh = mb_mul(mb_div(fw, Float64(width)), Float64(height))
    let pixels = Int(width * height)
    var rendered = InlineArray[UInt8, 256](fill=0)
    var pos = 0
    for image_x in range(Int(width)):
        let fx = mb_coord(cx, Int64(image_x), width, fw)
        for image_y in range(Int(height)):
            let fy = mb_coord(cy, Int64(image_y), height, fh)
            var a = fx; var b = fy; var current_step: Int64 = 0
            for step in range(Int(max_step)):
                current_step = Int64(step)
                let aa = mb_mul(a, a); let bb = mb_mul(b, b)
                let difference = mb_sub(aa, bb); let a_new = mb_add(difference, fx)
                let twice_a = mb_mul(2.0, a); let b_new = mb_add(mb_mul(twice_a, b), fy)
                a = a_new; b = b_new
                let magnitude = mb_add(mb_mul(a, a), mb_mul(b, b))
                if magnitude > 4.0: break
            let distance = mb_div(Float64(current_step), Float64(max_step - 1))
            rendered[pos] = 0 if distance >= 1.0 else 255
            pos += 1
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(pixels): return -2
    for i in range(pixels): out[i] = rendered[i]
    return Int64(pixels)
