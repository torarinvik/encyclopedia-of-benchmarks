const MAX_INPUT_LENGTH: usize = 4;
const MAX_TEMPERATURE_MK: i64 = 1_000_000;
const MAX_MOLAR_MASS_MICRO: i64 = 1_000_000_000;
const GAS_CONSTANT: f64 = 8.31446261815324;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;
const INVALID_RESULT: f64 = -1.0e300;

export fn speeds_of_gas_molecules(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    const operation = values[0];
    const temperature_mk = values[1];
    const molar_mass_micro = values[2];
    if (length != 3 or operation < 0 or operation > 1 or
        temperature_mk < 0 or temperature_mk > MAX_TEMPERATURE_MK or
        molar_mass_micro < 1 or molar_mass_micro > MAX_MOLAR_MASS_MICRO) return INVALID_RESULT;

    const temperature = @as(f64, @floatFromInt(temperature_mk)) / 1000.0;
    const molar_mass = @as(f64, @floatFromInt(molar_mass_micro)) / 1_000_000.0;
    if (operation == 0)
        return std.math.pow(f64, (8.0 * GAS_CONSTANT * temperature) / (PI_VALUE * molar_mass), 0.5);
    return std.math.pow(f64, (2.0 * GAS_CONSTANT * temperature) / molar_mass, 0.5);
}

const std = @import("std");
