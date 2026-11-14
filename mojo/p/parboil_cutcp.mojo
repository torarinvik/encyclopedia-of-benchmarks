# Clean-room Parboil cutoff-potential profile; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.math import ceil, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cutcp_decode(value: Int64) -> Float32:
    return Float32(value)/Float32(1000000.0)

@export("parboil_cutcp")
fn parboil_cutcp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 13 or length > 25: return -1
    let nxv = input[0]; let nyv = input[1]; let nzv = input[2]; let av = input[3]
    if nxv < 2 or nxv > 4 or nyv < 2 or nyv > 4 or nzv < 2 or nzv > 4 or av < 1 or av > 4: return -1
    let nx = Int(nxv); let ny = Int(nyv); let nz = Int(nzv); let count = Int(av)
    if length != c_size_t(9+4*count): return -1
    for axis in range(3):
        let origin = input[4+axis]
        if origin < -16000000 or origin > 16000000 or origin%1000000 != 0: return -1
    let spacing_raw = input[7]; let cutoff_raw = input[8]
    if spacing_raw < 1000000 or spacing_raw > 4000000 or spacing_raw%1000000 != 0 or cutoff_raw < 250000 or cutoff_raw > 4000000: return -1
    for i in range(count):
        let p = 9+4*i
        if input[p] < 0 or input[p] >= nxv-1 or input[p+1] < 0 or input[p+1] >= nyv-1 or input[p+2] < 0 or input[p+2] >= nzv-1 or input[p+3] < -1000000 or input[p+3] > 1000000: return -1
    let points = nx*ny*nz
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(4*points): return -2
    var origins = List[Float32](capacity=3)
    for axis in range(3): origins.append(cutcp_decode(input[4+axis]))
    let spacing = cutcp_decode(spacing_raw); let cutoff = cutcp_decode(cutoff_raw)
    let half = spacing*Float32(0.5)
    var coords = List[Float32](capacity=3*count)
    var charges = List[Float32](capacity=count)
    var minima = List[Float32](length=3, fill=0.0)
    var maxima = List[Float32](length=3, fill=0.0)
    for i in range(count):
        for axis in range(3):
            let v = origins[axis]+(Float32(input[9+4*i+axis])*spacing+half)
            coords.append(v)
            if i == 0 or v < minima[axis]: minima[axis] = v
            if i == 0 or v > maxima[axis]: maxima[axis] = v
        charges.append(cutcp_decode(input[12+4*i]))
    var cell_dims = List[Int](capacity=3)
    for axis in range(3): cell_dims.append(Int((maxima[axis]-minima[axis])*Float32(0.25))+1)
    let cells = cell_dims[0]*cell_dims[1]*cell_dims[2]
    var first = List[Int](length=cells, fill=-1)
    var next = List[Int](length=count, fill=-1)
    for i in range(count):
        if charges[i] == 0.0: continue
        let x = Int((coords[3*i]-minima[0])*Float32(0.25))
        let y = Int((coords[3*i+1]-minima[1])*Float32(0.25))
        let z = Int((coords[3*i+2]-minima[2])*Float32(0.25))
        let cell = (z*cell_dims[1]+y)*cell_dims[0]+x
        next[i] = first[cell]; first[cell] = i
    let cutoff2 = cutoff*cutoff
    let inv_cutoff2 = Float32(1.0)/cutoff2
    let inv_spacing = Float32(1.0)/spacing
    let radius = Int(ceil(cutoff*inv_spacing))-1
    var grid = List[Float32](length=points, fill=0.0)
    for cell in range(cells):
        var atom = first[cell]
        while atom >= 0:
            let x = coords[3*atom]-origins[0]; let y = coords[3*atom+1]-origins[1]; let z = coords[3*atom+2]-origins[2]
            let ic = Int(x*inv_spacing); let jc = Int(y*inv_spacing); let kc = Int(z*inv_spacing)
            var ia = ic-radius; var ib = ic+radius+1
            var ja = jc-radius; var jb = jc+radius+1
            var ka = kc-radius; var kb = kc+radius+1
            if ia < 0: ia = 0
            if ib >= nx: ib = nx-1
            if ja < 0: ja = 0
            if jb >= ny: jb = ny-1
            if ka < 0: ka = 0
            if kb >= nz: kb = nz-1
            let xstart = Float32(ia)*spacing-x
            let ystart = Float32(ja)*spacing-y
            var dz = Float32(ka)*spacing-z
            for k in range(ka,kb+1):
                let dz2 = dz*dz
                var dy = ystart
                for j in range(ja,jb+1):
                    let dydz2 = dy*dy+dz2
                    if dydz2 < cutoff2:
                        var dx = xstart
                        for i in range(ia,ib+1):
                            let r2 = dx*dx+dydz2
                            if r2 < cutoff2:
                                let s = Float32(1.0)-r2*inv_cutoff2
                                let reciprocal = Float32(1.0)/sqrt(r2)
                                var energy = charges[atom]*reciprocal
                                energy *= s; energy *= s
                                grid[(k*ny+j)*nx+i] += energy
                            dx += spacing
                    dy += spacing
                dz += spacing
            atom = next[atom]
    for i in range(points):
        let scaled = grid[i]*Float32(1000.0)
        var magnitude = scaled
        if magnitude < 0.0: magnitude = -magnitude
        var value = Int32(magnitude)
        if magnitude-Float32(value) >= Float32(0.5): value += 1
        if scaled < 0.0: value = -value
        for j in range(4): output[4*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(4*points)
