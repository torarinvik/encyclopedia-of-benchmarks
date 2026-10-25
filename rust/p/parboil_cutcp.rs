const MAX_DIM: usize = 4;
const MAX_ATOMS: usize = 4;
const MAX_INPUT: usize = 25;
const MAX_GRID: usize = 64;
const INV_CELL_LENGTH: f32 = 0.25;

#[derive(Clone, Copy)]
struct Atom { x: f32, y: f32, z: f32, q: f32 }

fn decode_component(raw: i64) -> f32 { raw as f32 / 1_000_000.0_f32 }

fn quantize_q(value: f32) -> i32 {
    let scaled = value * 1_000.0_f32;
    let magnitude = scaled.abs();
    let mut whole = magnitude as i32;
    if magnitude - whole as f32 >= 0.5_f32 { whole += 1; }
    if scaled < 0.0_f32 { -whole } else { whole }
}

fn write_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn parboil_cutcp(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 13 || input_length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 2 || values[0] > MAX_DIM as i64
            || values[1] < 2 || values[1] > MAX_DIM as i64
            || values[2] < 2 || values[2] > MAX_DIM as i64
            || values[3] < 1 || values[3] > MAX_ATOMS as i64 { return -1; }
    let nx = values[0] as usize;
    let ny = values[1] as usize;
    let nz = values[2] as usize;
    let atom_count = values[3] as usize;
    if input_length != 9 + 4 * atom_count { return -1; }
    let xlo_raw = values[4];
    let ylo_raw = values[5];
    let zlo_raw = values[6];
    let spacing_raw = values[7];
    let cutoff_raw = values[8];
    if xlo_raw < -16_000_000 || xlo_raw > 16_000_000
            || ylo_raw < -16_000_000 || ylo_raw > 16_000_000
            || zlo_raw < -16_000_000 || zlo_raw > 16_000_000
            || xlo_raw % 1_000_000 != 0 || ylo_raw % 1_000_000 != 0 || zlo_raw % 1_000_000 != 0
            || !(1_000_000..=4_000_000).contains(&spacing_raw) || spacing_raw % 1_000_000 != 0
            || !(250_000..=4_000_000).contains(&cutoff_raw) { return -1; }
    for n in 0..atom_count {
        let offset = 9 + 4 * n;
        if values[offset] < 0 || values[offset] >= (nx - 1) as i64
                || values[offset + 1] < 0 || values[offset + 1] >= (ny - 1) as i64
                || values[offset + 2] < 0 || values[offset + 2] >= (nz - 1) as i64
                || values[offset + 3] < -1_000_000 || values[offset + 3] > 1_000_000 { return -1; }
    }
    let points = nx * ny * nz;
    let output_bytes = 4 * points;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    let xlo = decode_component(xlo_raw);
    let ylo = decode_component(ylo_raw);
    let zlo = decode_component(zlo_raw);
    let spacing = decode_component(spacing_raw);
    let cutoff = decode_component(cutoff_raw);
    let half_spacing = spacing * 0.5_f32;
    let mut atoms = [Atom { x: 0.0, y: 0.0, z: 0.0, q: 0.0 }; MAX_ATOMS];
    for n in 0..atom_count {
        let offset = 9 + 4 * n;
        let ix = values[offset] as usize;
        let iy = values[offset + 1] as usize;
        let iz = values[offset + 2] as usize;
        atoms[n] = Atom {
            x: xlo + (ix as f32 * spacing + half_spacing),
            y: ylo + (iy as f32 * spacing + half_spacing),
            z: zlo + (iz as f32 * spacing + half_spacing),
            q: decode_component(values[offset + 3]),
        };
    }
    let (mut min_x, mut max_x) = (atoms[0].x, atoms[0].x);
    let (mut min_y, mut max_y) = (atoms[0].y, atoms[0].y);
    let (mut min_z, mut max_z) = (atoms[0].z, atoms[0].z);
    for atom in atoms.iter().take(atom_count).skip(1) {
        if atom.x < min_x { min_x = atom.x; }
        if atom.x > max_x { max_x = atom.x; }
        if atom.y < min_y { min_y = atom.y; }
        if atom.y > max_y { max_y = atom.y; }
        if atom.z < min_z { min_z = atom.z; }
        if atom.z > max_z { max_z = atom.z; }
    }
    let nx_cell = (((max_x - min_x) * INV_CELL_LENGTH).floor() as usize) + 1;
    let ny_cell = (((max_y - min_y) * INV_CELL_LENGTH).floor() as usize) + 1;
    let nz_cell = (((max_z - min_z) * INV_CELL_LENGTH).floor() as usize) + 1;
    let cell_count = nx_cell * ny_cell * nz_cell;
    let mut first = [-1_isize; MAX_GRID];
    let mut next = [-1_isize; MAX_ATOMS];
    for n in 0..atom_count {
        if atoms[n].q == 0.0_f32 { continue; }
        let i = ((atoms[n].x - min_x) * INV_CELL_LENGTH).floor() as usize;
        let j = ((atoms[n].y - min_y) * INV_CELL_LENGTH).floor() as usize;
        let k = ((atoms[n].z - min_z) * INV_CELL_LENGTH).floor() as usize;
        let cell = (k * ny_cell + j) * nx_cell + i;
        next[n] = first[cell];
        first[cell] = n as isize;
    }

    let cutoff_squared = cutoff * cutoff;
    let inv_cutoff_squared = 1.0_f32 / cutoff_squared;
    let inv_spacing = 1.0_f32 / spacing;
    let radius = (cutoff * inv_spacing).ceil() as isize - 1;
    let mut grid = [0.0_f32; MAX_GRID];
    for cell in 0..cell_count {
        let mut n = first[cell];
        while n != -1 {
            let atom_index = n as usize;
            let x = atoms[atom_index].x - xlo;
            let y = atoms[atom_index].y - ylo;
            let z = atoms[atom_index].z - zlo;
            let q = atoms[atom_index].q;
            let ic = (x * inv_spacing) as isize;
            let jc = (y * inv_spacing) as isize;
            let kc = (z * inv_spacing) as isize;
            let mut ia = ic - radius;
            let mut ib = ic + radius + 1;
            let mut ja = jc - radius;
            let mut jb = jc + radius + 1;
            let mut ka = kc - radius;
            let mut kb = kc + radius + 1;
            if ia < 0 { ia = 0; }
            if ib >= nx as isize { ib = nx as isize - 1; }
            if ja < 0 { ja = 0; }
            if jb >= ny as isize { jb = ny as isize - 1; }
            if ka < 0 { ka = 0; }
            if kb >= nz as isize { kb = nz as isize - 1; }
            let xstart = ia as f32 * spacing - x;
            let ystart = ja as f32 * spacing - y;
            let mut dz = ka as f32 * spacing - z;
            for k in ka..=kb {
                let koff = k as usize * ny;
                let dz2 = dz * dz;
                let mut dy = ystart;
                for j in ja..=jb {
                    let jkoff = (koff + j as usize) * nx;
                    let dydz2 = dy * dy + dz2;
                    if dydz2 < cutoff_squared {
                        let mut dx = xstart;
                        for i in ia..=ib {
                            let r2 = dx * dx + dydz2;
                            if r2 < cutoff_squared {
                                let s = 1.0_f32 - r2 * inv_cutoff_squared;
                                let reciprocal_r = 1.0_f32 / r2.sqrt();
                                let mut energy = q * reciprocal_r;
                                energy = energy * s;
                                energy = energy * s;
                                grid[jkoff + i as usize] = grid[jkoff + i as usize] + energy;
                            }
                            dx = dx + spacing;
                        }
                    }
                    dy = dy + spacing;
                }
                dz = dz + spacing;
            }
            n = next[atom_index];
        }
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for point in 0..points { write_i32_le(output_slice, 4 * point, quantize_q(grid[point])); }
    output_bytes as i64
}
