/// Compute a regular dodecahedron's area or volume from its edge length.
export fn dodecahedron(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const edge = values[0];
    const quantity = values[1];
    if (edge < 1 or edge > 1000000 or (quantity != 0 and quantity != 1)) return -1.0e300;

    const root_five = @sqrt(5.0);
    if (quantity == 0) {
        const area_factor = 3.0 * @sqrt(25.0 + 10.0 * root_five);
        return area_factor * @as(f64, @floatFromInt(edge * edge));
    }
    const volume_factor = (15.0 + 7.0 * root_five) / 4.0;
    return volume_factor * @as(f64, @floatFromInt(edge * edge * edge));
}
