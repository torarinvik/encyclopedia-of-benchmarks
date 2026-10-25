package parboil_cutcp

import "core:c"
import "core:math"

MAX_DIM :: 4
MAX_ATOMS :: 4
MAX_INPUT :: 25
MAX_GRID :: 64
INV_CELL_LENGTH :: f32(0.25)

Atom :: struct { x, y, z, q: f32 }

decode_component :: proc(raw: i64) -> f32 { return f32(raw) / 1_000_000.0 }

quantize_q :: proc(value: f32) -> i32 {
    scaled := value * 1_000.0
    magnitude := if scaled < 0.0 then -scaled else scaled
    whole := i32(magnitude)
    if magnitude - f32(whole) >= 0.5 do whole += 1
    if scaled < 0.0 do return -whole
    return whole
}

write_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    output[offset] = u8(bits)
    output[offset + 1] = u8(bits >> 8)
    output[offset + 2] = u8(bits >> 16)
    output[offset + 3] = u8(bits >> 24)
}

@(export)
parboil_cutcp :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 13 || input_length > MAX_INPUT do return -1
    if input[0] < 2 || input[0] > MAX_DIM || input[1] < 2 || input[1] > MAX_DIM
            || input[2] < 2 || input[2] > MAX_DIM || input[3] < 1 || input[3] > MAX_ATOMS do return -1
    nx, ny, nz, natoms := int(input[0]), int(input[1]), int(input[2]), int(input[3])
    if input_length != c.size_t(9 + 4*natoms) do return -1
    xlo_raw, ylo_raw, zlo_raw := input[4], input[5], input[6]
    spacing_raw, cutoff_raw := input[7], input[8]
    if xlo_raw < -16_000_000 || xlo_raw > 16_000_000
            || ylo_raw < -16_000_000 || ylo_raw > 16_000_000
            || zlo_raw < -16_000_000 || zlo_raw > 16_000_000
            || xlo_raw % 1_000_000 != 0 || ylo_raw % 1_000_000 != 0 || zlo_raw % 1_000_000 != 0
            || spacing_raw < 1_000_000 || spacing_raw > 4_000_000 || spacing_raw % 1_000_000 != 0
            || cutoff_raw < 250_000 || cutoff_raw > 4_000_000 do return -1
    for n := 0; n < natoms; n += 1 {
        offset := 9 + 4*n
        if input[offset] < 0 || input[offset] >= nx - 1 || input[offset+1] < 0
                || input[offset+1] >= ny - 1 || input[offset+2] < 0
                || input[offset+2] >= nz - 1 || input[offset+3] < -1_000_000
                || input[offset+3] > 1_000_000 do return -1
    }
    points := nx*ny*nz
    output_bytes := 4*points
    if output == nil || output_capacity < c.size_t(output_bytes) do return -2

    xlo, ylo, zlo := decode_component(xlo_raw), decode_component(ylo_raw), decode_component(zlo_raw)
    spacing, cutoff := decode_component(spacing_raw), decode_component(cutoff_raw)
    half_spacing := spacing * 0.5
    atoms: [MAX_ATOMS]Atom = {}
    for n := 0; n < natoms; n += 1 {
        offset := 9 + 4*n
        ix, iy, iz := int(input[offset]), int(input[offset+1]), int(input[offset+2])
        atoms[n] = Atom{xlo + (f32(ix)*spacing + half_spacing),
                        ylo + (f32(iy)*spacing + half_spacing),
                        zlo + (f32(iz)*spacing + half_spacing),
                        decode_component(input[offset+3])}
    }
    min_x, max_x := atoms[0].x, atoms[0].x
    min_y, max_y := atoms[0].y, atoms[0].y
    min_z, max_z := atoms[0].z, atoms[0].z
    for n := 1; n < natoms; n += 1 {
        if atoms[n].x < min_x do min_x = atoms[n].x
        if atoms[n].x > max_x do max_x = atoms[n].x
        if atoms[n].y < min_y do min_y = atoms[n].y
        if atoms[n].y > max_y do max_y = atoms[n].y
        if atoms[n].z < min_z do min_z = atoms[n].z
        if atoms[n].z > max_z do max_z = atoms[n].z
    }
    nx_cell := int(math.floor(f64((max_x - min_x)*INV_CELL_LENGTH))) + 1
    ny_cell := int(math.floor(f64((max_y - min_y)*INV_CELL_LENGTH))) + 1
    nz_cell := int(math.floor(f64((max_z - min_z)*INV_CELL_LENGTH))) + 1
    cell_count := nx_cell*ny_cell*nz_cell
    first: [MAX_GRID]int = {}
    next: [MAX_ATOMS]int = {}
    for c := 0; c < cell_count; c += 1 do first[c] = -1
    for n := 0; n < natoms; n += 1 do next[n] = -1
    for n := 0; n < natoms; n += 1 {
        if atoms[n].q == 0.0 do continue
        i := int(math.floor(f64((atoms[n].x-min_x)*INV_CELL_LENGTH)))
        j := int(math.floor(f64((atoms[n].y-min_y)*INV_CELL_LENGTH)))
        k := int(math.floor(f64((atoms[n].z-min_z)*INV_CELL_LENGTH)))
        cell := (k*ny_cell + j)*nx_cell + i
        next[n] = first[cell]
        first[cell] = n
    }

    cutoff_squared := cutoff*cutoff
    inv_cutoff_squared := f32(1.0)/cutoff_squared
    inv_spacing := f32(1.0)/spacing
    radius := int(math.ceil(f64(cutoff*inv_spacing))) - 1
    grid: [MAX_GRID]f32 = {}
    for c := 0; c < cell_count; c += 1 {
        n := first[c]
        for n != -1 {
            x, y, z, q := atoms[n].x-xlo, atoms[n].y-ylo, atoms[n].z-zlo, atoms[n].q
            ic, jc, kc := int(x*inv_spacing), int(y*inv_spacing), int(z*inv_spacing)
            ia, ib := ic-radius, ic+radius+1
            ja, jb := jc-radius, jc+radius+1
            ka, kb := kc-radius, kc+radius+1
            if ia < 0 do ia = 0
            if ib >= nx do ib = nx-1
            if ja < 0 do ja = 0
            if jb >= ny do jb = ny-1
            if ka < 0 do ka = 0
            if kb >= nz do kb = nz-1
            xstart, ystart := f32(ia)*spacing-x, f32(ja)*spacing-y
            dz := f32(ka)*spacing-z
            for k := ka; k <= kb; k += 1 {
                koff := k*ny
                dz2 := dz*dz
                dy := ystart
                for j := ja; j <= jb; j += 1 {
                    jkoff := (koff+j)*nx
                    dydz2 := dy*dy + dz2
                    if dydz2 < cutoff_squared {
                        dx := xstart
                        for i := ia; i <= ib; i += 1 {
                            r2 := dx*dx + dydz2
                            if r2 < cutoff_squared {
                                s := f32(1.0)-r2*inv_cutoff_squared
                                reciprocal_r := f32(1.0/math.sqrt(f64(r2)))
                                e := q*reciprocal_r
                                e = e*s
                                e = e*s
                                grid[jkoff+i] += e
                            }
                            dx += spacing
                        }
                    }
                    dy += spacing
                }
                dz += spacing
            }
            n = next[n]
        }
    }
    for point := 0; point < points; point += 1 {
        write_i32_le(output, 4*point, quantize_q(grid[point]))
    }
    return i64(output_bytes)
}
