# Bounded Rodinia LavaMD profile; see benchmarks/l/rodinia_lavamd/LICENSE.txt.
from std.ffi import c_size_t
from std.math import exp
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("rodinia_lavamd")
fn rodinia_lavamd(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 12 or length > 42:
        return -1
    let home = input[0]
    let neighbor = input[1]
    if home < 1 or home > 4 or neighbor < 1 or neighbor > 4:
        return -1
    let count = Int(home + neighbor)
    if length != c_size_t(2 + 5 * count):
        return -1
    var particles = InlineArray[Float64, 40](fill=0.0)
    for i in range(5 * count):
        let value = input[2 + i]
        if value < 0 or value > 1000000:
            return -1
        particles[i] = Float64(value) / 1000000.0

    var total: Float64 = 0.0
    for i in range(Int(home)):
        let a = 5 * i
        var potential: Float64 = 0.0
        var fx: Float64 = 0.0
        var fy: Float64 = 0.0
        var fz: Float64 = 0.0
        for j in range(count):
            let b = 5 * j
            let dot = particles[a + 1] * particles[b + 1] + particles[a + 2] * particles[b + 2] + particles[a + 3] * particles[b + 3]
            let r2 = particles[a] + particles[b] - dot
            let potential_pair = exp(-(0.5 * r2))
            let force_scale = 2.0 * potential_pair
            let charge = particles[b + 4]
            potential += charge * potential_pair
            fx += charge * (force_scale * (particles[a + 1] - particles[b + 1]))
            fy += charge * (force_scale * (particles[a + 2] - particles[b + 2]))
            fz += charge * (force_scale * (particles[a + 3] - particles[b + 3]))
        total += Float64(i + 1) * ((potential + fx) + fy + fz)
    let scaled = total * 1000000.0
    let rounded = if scaled < 0.0: -Int64(-scaled + 0.5) else: Int64(scaled + 0.5)
    return 1000000000000 + rounded
