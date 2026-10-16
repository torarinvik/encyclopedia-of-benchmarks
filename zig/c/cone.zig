const PI = 3.14159265358979323846;

export fn cone(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const operation = values[0];
    const radius = values[1];
    const height = values[2];
    if ((operation != 0 and operation != 1) or radius < 0 or radius > 1000 or
        height < 0 or height > 1000) return -1.0e300;
    const radius_value = @as(f64, @floatFromInt(radius));
    const radius_squared = radius_value * radius_value;
    const base_area = radius_squared * PI;
    if (operation == 0) return (base_area * @as(f64, @floatFromInt(height)) * 1.0) / 3.0;
    const height_value = @as(f64, @floatFromInt(height));
    return base_area + PI * radius_value * @sqrt(radius_squared + height_value * height_value);
}
