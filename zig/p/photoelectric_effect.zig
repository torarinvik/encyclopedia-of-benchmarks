/// Photoelectric maximum electron kinetic energy in electronvolts.
export fn photoelectric_effect(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const frequency = values[0];
    const work_function = values[1];
    if (frequency < 0 or frequency > 1_000_000_000_000_000_000 or work_function < 0 or work_function > 1000)
        return -1.0e300;
    const photon_energy = 4.1357e-15 * @as(f64, @floatFromInt(frequency));
    const energy_difference = photon_energy - @as(f64, @floatFromInt(work_function));
    return if (energy_difference > 0.0) energy_difference else 0.0;
}
