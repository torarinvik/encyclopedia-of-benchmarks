const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const MAX_PHYSICAL: i64 = 1_000_000_000_000_000;
const MAX_FLUX_RATE: i64 = 1_000_000_000_000_000_000;
const MIN_CONSTANT: i64 = 1_000_000;
const MAX_CONSTANT: i64 = 1_000_000_000_000_000;
const EPSILON_DEFAULT: f64 = 8.8541878128e-12;
const MU_DEFAULT: f64 = 4.0 * 3.14159265358979323846264338327950288 * 1e-7;

fn inRange(value: i64, limit: i64) bool { return value >= -limit and value <= limit; }
fn decodeConstant(raw: i64, fallback: f64) ?f64 {
    if (raw == 0) return fallback;
    if (raw < MIN_CONSTANT or raw > MAX_CONSTANT) return null;
    return @as(f64, @floatFromInt(raw)) / 1e18;
}
fn lawResult(actual: f64, expected: f64) f64 {
    const tolerance = if (expected != 0.0) 0.01 * @abs(expected) else 1e-10;
    return if (@abs(actual - expected) <= tolerance) 1.0 else 0.0;
}

export fn maxwells_equations(input_opt: ?[*]const i64, length: usize) f64 {
    if (input_opt == null or length < 1 or length > 7) return INVALID_RESULT;
    const input = input_opt.?;
    const operation = input[0];
    if (operation == 0) {
        if (length != 5) return INVALID_RESULT;
        const field = input[1]; const area = input[2]; const charge = input[3]; const epsilon_raw = input[4];
        if (!inRange(field, MAX_PHYSICAL) or area < 0 or area > MAX_PHYSICAL or !inRange(charge, MAX_PHYSICAL)) return INVALID_RESULT;
        const epsilon = decodeConstant(epsilon_raw, EPSILON_DEFAULT) orelse return INVALID_RESULT;
        const electric_flux = (@as(f64, @floatFromInt(field)) / 1e12) * (@as(f64, @floatFromInt(area)) / 1e12);
        const expected_flux = (@as(f64, @floatFromInt(charge)) / 1e12) / epsilon;
        return lawResult(electric_flux, expected_flux);
    }
    if (operation == 1) {
        if (length != 3 or !inRange(input[1], MAX_PHYSICAL) or !inRange(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        const circulation = @as(f64, @floatFromInt(input[1])) / 1e12;
        const expected = -(@as(f64, @floatFromInt(input[2])) / 1e12);
        return lawResult(circulation, expected);
    }
    if (operation == 2) {
        if (length != 6 or !inRange(input[1], MAX_PHYSICAL) or !inRange(input[2], MAX_PHYSICAL) or !inRange(input[3], MAX_FLUX_RATE)) return INVALID_RESULT;
        const mu = decodeConstant(input[4], MU_DEFAULT) orelse return INVALID_RESULT;
        const epsilon = decodeConstant(input[5], EPSILON_DEFAULT) orelse return INVALID_RESULT;
        const displacement_current = epsilon * (@as(f64, @floatFromInt(input[3])) / 1e6);
        const total_current = (@as(f64, @floatFromInt(input[2])) / 1e12) + displacement_current;
        const expected = mu * total_current;
        return lawResult(@as(f64, @floatFromInt(input[1])) / 1e12, expected);
    }
    if (operation == 3 or operation == 4) {
        if (length != 3) return INVALID_RESULT;
        const mu = decodeConstant(input[1], MU_DEFAULT) orelse return INVALID_RESULT;
        const epsilon = decodeConstant(input[2], EPSILON_DEFAULT) orelse return INVALID_RESULT;
        if (operation == 3) return 1.0 / @sqrt(mu * epsilon);
        return @sqrt(mu / epsilon);
    }
    if (operation == 5) {
        if (length != 4 or !inRange(input[1], MAX_PHYSICAL) or !inRange(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        const mu = decodeConstant(input[3], MU_DEFAULT) orelse return INVALID_RESULT;
        return ((@as(f64, @floatFromInt(input[1])) / 1e12) * (@as(f64, @floatFromInt(input[2])) / 1e12)) / mu;
    }
    if (operation == 6) {
        if (length != 5 or !inRange(input[1], MAX_PHYSICAL) or !inRange(input[2], MAX_PHYSICAL)) return INVALID_RESULT;
        const epsilon = decodeConstant(input[3], EPSILON_DEFAULT) orelse return INVALID_RESULT;
        const mu = decodeConstant(input[4], MU_DEFAULT) orelse return INVALID_RESULT;
        const electric_field = @as(f64, @floatFromInt(input[1])) / 1e12;
        const magnetic_field = @as(f64, @floatFromInt(input[2])) / 1e12;
        const electric_energy = 0.5 * epsilon * (electric_field * electric_field);
        const magnetic_energy = 0.5 * (magnetic_field * magnetic_field) / mu;
        return electric_energy + magnetic_energy;
    }
    return INVALID_RESULT;
}
