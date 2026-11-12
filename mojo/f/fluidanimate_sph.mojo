from std.ffi import c_size_t
from std.math import pow, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_PARTICLES = 32
alias MAX_INPUT_LENGTH = 2 + 6 * MAX_PARTICLES
alias PI = 3.14159265358979323846264338327950288

fn fluidanimate_sph_store_f64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Float64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("fluidanimate_sph")
fn fluidanimate_sph(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let count_value = input[0]
    let rpm_milli = input[1]
    if count_value < 1 or count_value > MAX_PARTICLES or rpm_milli < 500 or rpm_milli > 5000:
        return -1
    let count = Int(count_value)
    if length != c_size_t(2 + 6 * count): return -1
    for i in range(count):
        let base = 2 + 6 * i
        for axis in range(3):
            if input[base + axis] < -10000 or input[base + axis] > 10000: return -1
        for axis in range(3):
            if input[base + 3 + axis] < -5000 or input[base + 3 + axis] > 5000: return -1
    let output_bytes = 40 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var position = InlineArray[Float64, 96]()
    var velocity = InlineArray[Float64, 96]()
    var acceleration = InlineArray[Float64, 96]()
    var density = InlineArray[Float64, MAX_PARTICLES]()
    let rpm = Float64(rpm_milli) / 1000.0
    let h = 1.695 / rpm
    let h2 = h * h
    let mass = 1000.0 / (rpm * rpm * rpm)
    let density_coeff = mass * (315.0 / (64.0 * PI * pow(h, 9.0)))
    let pressure_coeff = 3.0 * (15.0 / (PI * pow(h, 6.0))) * 1.5 * mass
    let viscosity_coeff = 0.4 * (45.0 / (PI * pow(h, 6.0))) * mass
    for i in range(count):
        let base = 2 + 6 * i
        for axis in range(3):
            position[3 * i + axis] = Float64(input[base + axis]) / 1000.0
            velocity[3 * i + axis] = Float64(input[base + 3 + axis]) / 1000.0
            acceleration[3 * i + axis] = -9.8 if axis == 1 else 0.0
        density[i] = density_coeff * h2 * h2 * h2
    for i in range(count):
        for j in range(i + 1, count):
            let dx = position[3 * i] - position[3 * j]
            let dy = position[3 * i + 1] - position[3 * j + 1]
            let dz = position[3 * i + 2] - position[3 * j + 2]
            let r2 = dx * dx + dy * dy + dz * dz
            if r2 < h2:
                let term = density_coeff * pow(h2 - r2, 3.0)
                density[i] += term
                density[j] += term
    for i in range(count):
        for j in range(i + 1, count):
            let dx = position[3 * i] - position[3 * j]
            let dy = position[3 * i + 1] - position[3 * j + 1]
            let dz = position[3 * i + 2] - position[3 * j + 2]
            let r2 = dx * dx + dy * dy + dz * dz
            if r2 >= h2: continue
            let guarded_r2 = r2 if r2 > 1e-12 else 1e-12
            let distance = sqrt(guarded_r2)
            let hmr = h - distance
            let rho_product = density[i] * density[j]
            let pressure_scale = pressure_coeff * (hmr * hmr / distance) * (
                density[i] + density[j] - 2000.0
            ) / rho_product
            let viscosity_scale = viscosity_coeff * hmr / rho_product
            for axis in range(3):
                let displacement = dx if axis == 0 else (dy if axis == 1 else dz)
                let force = displacement * pressure_scale + (
                    velocity[3 * j + axis] - velocity[3 * i + axis]
                ) * viscosity_scale
                acceleration[3 * i + axis] += force
                acceleration[3 * j + axis] -= force
    for i in range(count):
        let base = 5 * i
        fluidanimate_sph_store_f64(output, 8 * base, density[i])
        fluidanimate_sph_store_f64(output, 8 * (base + 1), 3.0 * (density[i] - 1000.0))
        for axis in range(3):
            fluidanimate_sph_store_f64(output, 8 * (base + 2 + axis), acceleration[3 * i + axis])
    return Int64(output_bytes)
