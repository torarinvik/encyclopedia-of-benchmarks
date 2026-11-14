# Independent bounded five-body simulation; see the package provenance.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn nbody_energy(position: InlineArray[Float64, 15], velocity: InlineArray[Float64, 15],
                mass: InlineArray[Float64, 5]) -> Float64:
    var result: Float64 = 0.0
    for i in range(5):
        let k = 3 * i
        result += 0.5 * mass[i] * (velocity[k] * velocity[k] + velocity[k + 1] * velocity[k + 1] + velocity[k + 2] * velocity[k + 2])
        for j in range(i + 1, 5):
            let dx = position[k] - position[3 * j]
            let dy = position[k + 1] - position[3 * j + 1]
            let dz = position[k + 2] - position[3 * j + 2]
            result -= mass[i] * mass[j] / sqrt(dx * dx + dy * dy + dz * dz)
    return result

@export("benchmarkgame_nbody")
fn benchmarkgame_nbody(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    if input[0] < 0 or input[0] > 1000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    let solar: Float64 = 4.0 * 3.141592653589793 * 3.141592653589793
    let days: Float64 = 365.24
    var mass = InlineArray[Float64, 5](solar, 9.54791938424326609e-4 * solar,
        2.85885980666130812e-4 * solar, 4.36624404335156298e-5 * solar,
        5.15138902046611451e-5 * solar)
    var position = InlineArray[Float64, 15](0.0, 0.0, 0.0,
        4.84143144246472090, -1.16032004402742839, -0.103622044471123109,
        8.34336671824457987, 4.12479856412430479, -0.403523417114321381,
        12.8943695621391310, -15.1111514016986312, -0.223307578892655734,
        15.3796971148509165, -25.9193146099879641, 0.179258772950371181)
    var velocity = InlineArray[Float64, 15](0.0, 0.0, 0.0,
        1.66007664274403694e-3 * days, 7.69901118419740425e-3 * days, -6.90460016972063023e-5 * days,
        -2.76742510726862411e-3 * days, 4.99852801234917238e-3 * days, 2.30417297573763929e-5 * days,
        2.96460137564761618e-3 * days, 2.37847173959480950e-3 * days, -2.96589568540237556e-5 * days,
        2.68067772490389322e-3 * days, 1.62824170038242295e-3 * days, -9.51592254519715870e-5 * days)
    for axis in range(3):
        var momentum: Float64 = 0.0
        for i in range(5): momentum += velocity[3 * i + axis] * mass[i]
        velocity[axis] = -momentum / solar
    let initial = nbody_energy(position, velocity, mass)
    for step in range(Int(input[0])):
        for i in range(5):
            for j in range(i + 1, 5):
                let dx = position[3 * i] - position[3 * j]
                let dy = position[3 * i + 1] - position[3 * j + 1]
                let dz = position[3 * i + 2] - position[3 * j + 2]
                let distance = sqrt(dx * dx + dy * dy + dz * dz)
                let magnitude = 0.01 / (distance * distance * distance)
                let delta = InlineArray[Float64, 3](dx, dy, dz)
                for axis in range(3):
                    velocity[3 * i + axis] -= delta[axis] * mass[j] * magnitude
                    velocity[3 * j + axis] += delta[axis] * mass[i] * magnitude
        for i in range(15): position[i] += 0.01 * velocity[i]
    let final_energy = nbody_energy(position, velocity, mass)
    let energies = InlineArray[Float64, 2](initial, final_energy)
    for i in range(2):
        let bits = bitcast[UInt64](energies[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return 16
