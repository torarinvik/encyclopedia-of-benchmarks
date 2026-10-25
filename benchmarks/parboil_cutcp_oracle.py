"""Independent bounded oracle for Parboil's cutoff-potential lattice kernel."""

from collections.abc import Sequence
import math
import struct

MAX_DIMENSION = 4
MIN_DIMENSION = 2
MAX_ATOMS = 4
MAX_GRID_POINTS = MAX_DIMENSION ** 3
MAX_INPUT_LENGTH = 9 + 4 * MAX_ATOMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_COMPONENT_RAW = 1_000_000
MAX_ORIGIN_RAW = 16_000_000
MAX_OUTPUT_BYTES = 4 * MAX_GRID_POINTS
OUTPUT_SCALE = 1_000
CELL_LENGTH = 4.0
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _f32(value: float | int) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _decode(raw: int) -> float:
    return _f32(_f32(raw) / _f32(1_000_000))


def _round_away(value: float) -> int:
    scaled = _f32(_f32(value) * _f32(OUTPUT_SCALE))
    whole = math.floor(abs(scaled) + 0.5)
    return -whole if scaled < 0.0 else whole


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[tuple[int, int, int], list[tuple[float, float, float, float]],
                                         tuple[float, float, float], float, float] | None:
    if (not isinstance(values, (tuple, list)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or (input_length is not None
                and (type(input_length) is not int
                     or not 0 <= input_length <= MAX_INPUT_LENGTH))
            or (input_is_null and values)
            or (not input_is_null and input_length is not None
                and input_length != len(values))):
        return None
    if input_is_null or len(values) < 13:
        return None

    nx, ny, nz, atom_count = values[:4]
    if (not MIN_DIMENSION <= nx <= MAX_DIMENSION
            or not MIN_DIMENSION <= ny <= MAX_DIMENSION
            or not MIN_DIMENSION <= nz <= MAX_DIMENSION
            or not 1 <= atom_count <= MAX_ATOMS
            or len(values) != 9 + 4 * atom_count):
        return None
    xlo_raw, ylo_raw, zlo_raw, spacing_raw, cutoff_raw = values[4:9]
    if (any(abs(value) > MAX_ORIGIN_RAW for value in (xlo_raw, ylo_raw, zlo_raw))
            or any(value % 1_000_000 for value in (xlo_raw, ylo_raw, zlo_raw))
            or not 1_000_000 <= spacing_raw <= 4_000_000
            or spacing_raw % 1_000_000
            or not 250_000 <= cutoff_raw <= 4_000_000):
        return None

    xlo, ylo, zlo = (_decode(value) for value in (xlo_raw, ylo_raw, zlo_raw))
    spacing = _decode(spacing_raw)
    cutoff = _decode(cutoff_raw)
    atoms: list[tuple[float, float, float, float]] = []
    offset = 9
    for _ in range(atom_count):
        ix, iy, iz, charge_raw = values[offset:offset + 4]
        if (not 0 <= ix < nx - 1 or not 0 <= iy < ny - 1
                or not 0 <= iz < nz - 1
                or abs(charge_raw) > MAX_COMPONENT_RAW):
            return None
        half_spacing = _f32(spacing * _f32(0.5))
        x = _f32(xlo + _f32(_f32(ix) * spacing + half_spacing))
        y = _f32(ylo + _f32(_f32(iy) * spacing + half_spacing))
        z = _f32(zlo + _f32(_f32(iz) * spacing + half_spacing))
        atoms.append((x, y, z, _decode(charge_raw)))
        offset += 4
    return (nx, ny, nz), atoms, (xlo, ylo, zlo), spacing, cutoff


def _compute(values: Sequence[int]) -> bytes:
    parsed = _parse(values, len(values), False)
    assert parsed is not None
    (nx, ny, nz), atoms, (xlo, ylo, zlo), spacing, cutoff = parsed

    min_x = max_x = atoms[0][0]
    min_y = max_y = atoms[0][1]
    min_z = max_z = atoms[0][2]
    for x, y, z, _charge in atoms[1:]:
        min_x, max_x = min(min_x, x), max(max_x, x)
        min_y, max_y = min(min_y, y), max(max_y, y)
        min_z, max_z = min(min_z, z), max(max_z, z)

    inv_cell_length = _f32(1.0 / _f32(CELL_LENGTH))
    nx_cell = math.floor(_f32(_f32(max_x - min_x) * inv_cell_length)) + 1
    ny_cell = math.floor(_f32(_f32(max_y - min_y) * inv_cell_length)) + 1
    nz_cell = math.floor(_f32(_f32(max_z - min_z) * inv_cell_length)) + 1
    cell_count = nx_cell * ny_cell * nz_cell
    first = [-1] * cell_count
    next_atom = [-1] * len(atoms)

    for atom_index, (x, y, z, charge) in enumerate(atoms):
        if charge == 0.0:
            continue
        i = math.floor(_f32(_f32(x - min_x) * inv_cell_length))
        j = math.floor(_f32(_f32(y - min_y) * inv_cell_length))
        k = math.floor(_f32(_f32(z - min_z) * inv_cell_length))
        cell_index = (k * ny_cell + j) * nx_cell + i
        next_atom[atom_index] = first[cell_index]
        first[cell_index] = atom_index

    inv_grid_spacing = _f32(1.0 / spacing)
    cutoff_squared = _f32(cutoff * cutoff)
    inv_cutoff_squared = _f32(1.0 / cutoff_squared)
    radius = math.ceil(_f32(cutoff * inv_grid_spacing)) - 1
    grid = [_f32(0.0)] * (nx * ny * nz)

    for cell_index in range(cell_count):
        atom_index = first[cell_index]
        while atom_index != -1:
            atom_x, atom_y, atom_z, charge = atoms[atom_index]
            x = _f32(atom_x - xlo)
            y = _f32(atom_y - ylo)
            z = _f32(atom_z - zlo)
            ic = int(_f32(x * inv_grid_spacing))
            jc = int(_f32(y * inv_grid_spacing))
            kc = int(_f32(z * inv_grid_spacing))
            ia, ib = max(0, ic - radius), min(nx - 1, ic + radius + 1)
            ja, jb = max(0, jc - radius), min(ny - 1, jc + radius + 1)
            ka, kb = max(0, kc - radius), min(nz - 1, kc + radius + 1)

            x_start = _f32(_f32(ia * spacing) - x)
            y_start = _f32(_f32(ja * spacing) - y)
            dz = _f32(_f32(ka * spacing) - z)
            for k in range(ka, kb + 1):
                k_offset = k * ny
                dz_squared = _f32(dz * dz)
                dy = y_start
                for j in range(ja, jb + 1):
                    jk_offset = (k_offset + j) * nx
                    dyz_squared = _f32(_f32(dy * dy) + dz_squared)
                    if dyz_squared < cutoff_squared:
                        dx = x_start
                        for i in range(ia, ib + 1):
                            radius_squared = _f32(_f32(dx * dx) + dyz_squared)
                            if radius_squared < cutoff_squared:
                                taper = _f32(1.0 - _f32(radius_squared * inv_cutoff_squared))
                                reciprocal_r = _f32(1.0 / _f32(math.sqrt(radius_squared)))
                                energy = _f32(charge * reciprocal_r)
                                energy = _f32(energy * taper)
                                energy = _f32(energy * taper)
                                grid[jk_offset + i] = _f32(grid[jk_offset + i] + energy)
                            dx = _f32(dx + spacing)
                    dy = _f32(dy + spacing)
                dz = _f32(dz + spacing)
            atom_index = next_atom[atom_index]

    return b"".join(struct.pack("<i", _round_away(value)) for value in grid)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID_RESULT, b""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    nx, ny, nz = parsed[0]
    output_bytes = 4 * nx * ny * nz
    if output_is_null or output_capacity is not None and output_capacity < output_bytes:
        return OUTPUT_ERROR, b""
    output = _compute(values)
    return output_bytes, output
