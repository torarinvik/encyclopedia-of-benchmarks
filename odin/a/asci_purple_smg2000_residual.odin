// Clean-room bounded residual profile; see package README and RIGHTS.md.
package asci_purple_smg2000_residual
import "core:c"
import "core:math"

@(export)
asci_purple_smg2000_residual :: proc "c" (input: [^]f64, length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || length < 19 || length > 253 do return -1
    for q := 0; q < 3; q += 1 {
        v := input[q]
        if v != v || math.trunc(v) != v || v < 2 || v > 5 do return -1
    }
    nx, ny, nz := int(input[0]), int(input[1]), int(input[2])
    cells := nx * ny * nz
    if length != c.size_t(3 + 2 * cells) do return -1
    for q := 3; q < int(length); q += 1 {
        v := input[q]
        if v != v || math.trunc(v) != v || v < -1000 || v > 1000 do return -1
    }
    if output == nil || capacity < c.size_t(cells) do return -2
    si, sj := ny * nz, nz
    for i := 0; i < nx; i += 1 {
        for j := 0; j < ny; j += 1 {
            for k := 0; k < nz; k += 1 {
                q := i * si + j * sj + k
                x := i64(input[3 + q])
                ax := i64(222) * x
                if i > 0 do ax -= i64(input[3 + q - si])
                if i + 1 < nx do ax -= i64(input[3 + q + si])
                if j > 0 do ax -= i64(10) * i64(input[3 + q - sj])
                if j + 1 < ny do ax -= i64(10) * i64(input[3 + q + sj])
                if k > 0 do ax -= i64(100) * i64(input[3 + q - 1])
                if k + 1 < nz do ax -= i64(100) * i64(input[3 + q + 1])
                b := i64(input[3 + cells + q])
                output[q] = f64(10 * b - ax) / 10.0
            }
        }
    }
    return i64(cells)
}
