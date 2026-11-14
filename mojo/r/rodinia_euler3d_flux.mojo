# Independent bounded Rodinia Euler3D profile; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

# A flow record stores density, momentum, energy, pressure, velocity,
# speed, sound, momentum-flux matrix and energy-flux vector.
fn euler_flow(mut flow: List[Float32], density: Float32, mx: Float32, my: Float32,
              mz: Float32, energy: Float32, pressure_override: Float32) -> Bool:
    flow[0] = density; flow[1] = mx; flow[2] = my; flow[3] = mz; flow[4] = energy
    for d in range(3): flow[6+d] = flow[1+d]/density
    var speed2 = flow[6]*flow[6]
    speed2 += flow[7]*flow[7]; speed2 += flow[8]*flow[8]
    let kinetic = (Float32(0.5)*density)*speed2
    var pressure = (Float32(1.4)-Float32(1.0))*(energy-kinetic)
    if pressure_override > 0.0: pressure = pressure_override
    if not isfinite(pressure) or pressure <= 0.0: return False
    flow[5] = pressure; flow[9] = sqrt(speed2); flow[10] = sqrt((Float32(1.4)*pressure)/density)
    let ep = energy+pressure
    for axis in range(3):
        for component in range(3):
            if component >= axis:
                var value = flow[6+axis]*flow[1+component]
                if axis == component: value += pressure
                flow[11+3*axis+component] = value
                flow[11+3*component+axis] = value
        flow[20+axis] = flow[6+axis]*ep
    return isfinite(flow[9]) and isfinite(flow[10])

fn euler_read(input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int, mut flow: List[Float32]) -> Bool:
    var raw = List[Float32](capacity=5)
    for i in range(5):
        let value = input[offset+i]
        if value < 0 or value > 4294967295: return False
        let bits = UInt32(value)
        if (bits & UInt32(0x7f800000)) == UInt32(0x7f800000): return False
        raw.append(bits.bitcast[Float32]())
    if raw[0] < 0.5 or raw[0] > 2.0 or raw[4] < 1.0 or raw[4] > 5.0: return False
    for i in range(1,4):
        if raw[i] < -1.0 or raw[i] > 1.0: return False
    return euler_flow(flow,raw[0],raw[1],raw[2],raw[3],raw[4],0.0)

@export("rodinia_euler3d_flux")
fn rodinia_euler3d_flux(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 41: return -1
    var center = List[Float32](length=23, fill=0.0)
    if not euler_read(input,0,center): return -1
    var normals = List[Float32](capacity=12)
    var kinds = List[Int](capacity=4)
    var neighbor_data = List[Float32](capacity=92)
    for face in range(4):
        let at = 5+9*face; let kind = input[at]
        if kind < -2 or kind > 0: return -1
        kinds.append(Int(kind))
        for axis in range(3):
            let raw = input[at+1+axis]
            if raw < 0 or raw > 4294967295: return -1
            let bits = UInt32(raw)
            if (bits & UInt32(0x7f800000)) == UInt32(0x7f800000): return -1
            let value = bits.bitcast[Float32]()
            if value < -1.0 or value > 1.0: return -1
            normals.append(value)
        var neighbor = List[Float32](length=23, fill=0.0)
        if not euler_read(input,at+4,neighbor): return -1
        for value in neighbor: neighbor_data.append(value)
    let gamma = Float32(1.4)
    let sound = sqrt((gamma*Float32(1.0))/Float32(1.4))
    let speed = Float32(1.2)*sound
    let density = Float32(1.4)
    let energy = density*(Float32(0.5)*(speed*speed))+Float32(1.0)/(gamma-Float32(1.0))
    var far = List[Float32](length=23, fill=0.0)
    if not euler_flow(far,density,density*speed,0.0,0.0,energy,1.0): return -1
    # The source computes the far-field speed before converting velocity to momentum.
    far[6] = speed; far[9] = speed; far[10] = sound
    far[11] = speed*far[1]+far[5]
    far[12] = speed*far[2]; far[13] = speed*far[3]
    far[14] = far[12]; far[17] = far[13]
    far[20] = speed*(far[4]+far[5])
    var flux = List[Float32](length=5, fill=0.0)
    for face in range(4):
        let nx = normals[3*face]; let ny = normals[3*face+1]; let nz = normals[3*face+2]
        let normal_length = sqrt((nx*nx+ny*ny)+nz*nz)
        if kinds[face] == -1:
            for axis in range(3): flux[1+axis] += normals[3*face+axis]*center[5]
            continue
        var other = List[Float32](length=23, fill=0.0)
        if kinds[face] == -2:
            for i in range(23): other[i] = far[i]
        else:
            for i in range(23): other[i] = neighbor_data[23*face+i]
            var factor = -normal_length*Float32(0.2)
            factor *= Float32(0.5)
            var speed_sum = center[9]+other[9]
            speed_sum += center[10]; speed_sum += other[10]
            factor *= speed_sum
            flux[0] += factor*(center[0]-other[0])
            flux[4] += factor*(center[4]-other[4])
            for c in range(3): flux[1+c] += factor*(center[1+c]-other[1+c])
        for axis in range(3):
            let factor = Float32(0.5)*normals[3*face+axis]
            flux[0] += factor*(other[1+axis]+center[1+axis])
            flux[4] += factor*(other[20+axis]+center[20+axis])
            for c in range(3): flux[1+c] += factor*(other[11+3*axis+c]+center[11+3*axis+c])
    var checksum = Int64(0)
    for i in range(5):
        if not isfinite(flux[i]): return -1
        let scaled = Float64(flux[i])*1000.0
        var magnitude = scaled
        if magnitude < 0.0: magnitude = -magnitude
        var rounded = Int64(magnitude)
        if magnitude-Float64(rounded) >= 0.5: rounded += 1
        if scaled < 0.0: rounded = -rounded
        checksum += Int64(i+1)*rounded
    return checksum
