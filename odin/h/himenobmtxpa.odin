package himenobmtxpa

import "core:c"
import "core:math"

@(export, link_name="himenobmtxpa")
himenobmtxpa :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || length != 4 do return -1
    var dims: [4]int
    for q := 0; q < 4; q += 1 {
        value := input[q]
        if value != value || math.trunc(value) != value do return -1
        if q < 3 {
            if value < 2 || value > 6 do return -1
        } else {
            if value < 1 || value > 4 do return -1
        }
        dims[q] = int(value)
    }
    nx, ny, nz, iterations := dims[0], dims[1], dims[2], dims[3]
    if output == nil || capacity < 1 do return -2

    var p: [216]f32
    var work: [216]f32
    a3 := f32(1) / f32(6)
    omega := f32(0.8)
    denominator := f32((nx - 1) * (nx - 1))
    for i := 0; i < nx; i += 1 {
        for j := 0; j < ny; j += 1 {
            for k := 0; k < nz; k += 1 {
                q := i * ny * nz + j * nz + k
                p[q] = f32(i * i) / denominator
            }
        }
    }
    gosa := f32(0)
    for iteration := 0; iteration < iterations; iteration += 1 {
        gosa = 0
        for i := 1; i < nx-1; i += 1 {
            for j := 1; j < ny-1; j += 1 {
                for k := 1; k < nz-1; k += 1 {
                    q := i * ny * nz + j * nz + k
                    s0 := p[q+ny*nz] + p[q+nz] + p[q+1]
                    s0 = s0 + p[q-ny*nz] + p[q-nz] + p[q-1]
                    ss := s0*a3 - p[q]
                    gosa = gosa + ss*ss
                    work[q] = p[q] + omega*ss
                }
            }
        }
        for i := 1; i < nx-1; i += 1 {
            for j := 1; j < ny-1; j += 1 {
                for k := 1; k < nz-1; k += 1 {
                    q := i * ny * nz + j * nz + k
                    p[q] = work[q]
                }
            }
        }
    }
    output[0] = f64(gosa)
    return 1
}
