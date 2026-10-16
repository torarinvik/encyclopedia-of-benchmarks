const COORDINATE_LIMIT: i64 = 64;
const MAX_PIXELS: usize = 258;

#[derive(Clone, Copy)]
struct Endpoint {
    x_pixel: i64,
    y_pixel: i64,
    y_end: f64,
    x_gap: f64,
}

fn fraction_part(value: f64) -> f64 { value - value.floor() }
fn reverse_fraction_part(value: f64) -> f64 { 1.0 - fraction_part(value) }

fn add_pixel(pixel_x: &mut [i64; MAX_PIXELS], pixel_y: &mut [i64; MAX_PIXELS],
             intensities: &mut [f64; MAX_PIXELS], count: &mut usize,
             mut x: i64, mut y: i64, intensity: f64, steep: bool) {
    if steep { std::mem::swap(&mut x, &mut y); }
    pixel_x[*count] = x;
    pixel_y[*count] = y;
    intensities[*count] = intensity.clamp(0.0, 1.0);
    *count += 1;
}

fn add_endpoint(pixel_x: &mut [i64; MAX_PIXELS], pixel_y: &mut [i64; MAX_PIXELS],
                intensities: &mut [f64; MAX_PIXELS], count: &mut usize,
                endpoint: Endpoint, steep: bool) {
    let fractional_y = fraction_part(endpoint.y_end);
    let complement = reverse_fraction_part(endpoint.y_end);
    add_pixel(pixel_x, pixel_y, intensities, count, endpoint.x_pixel,
              endpoint.y_pixel, complement * endpoint.x_gap, steep);
    add_pixel(pixel_x, pixel_y, intensities, count, endpoint.x_pixel,
              endpoint.y_pixel + 1, fractional_y * endpoint.x_gap, steep);
}

unsafe fn write_i32_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = (value as i32).to_le_bytes();
    for (byte, value) in bytes.iter().enumerate() { *output.add(offset + byte) = *value; }
}

unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for (byte, value) in bytes.iter().enumerate() { *output.add(offset + byte) = *value; }
}

#[no_mangle]
pub unsafe extern "C" fn wus_line(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 4 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|value| *value < -COORDINATE_LIMIT || *value > COORDINATE_LIMIT) {
        return -1;
    }

    let mut x0 = values[0];
    let mut y0 = values[1];
    let mut x1 = values[2];
    let mut y1 = values[3];
    let steep = (y1 - y0).abs() > (x1 - x0).abs();
    if steep { std::mem::swap(&mut x0, &mut y0); std::mem::swap(&mut x1, &mut y1); }
    if x0 > x1 { std::mem::swap(&mut x0, &mut x1); std::mem::swap(&mut y0, &mut y1); }

    let delta_x = x1 as f64 - x0 as f64;
    let delta_y = y1 as f64 - y0 as f64;
    let gradient = if delta_x == 0.0 { 1.0 } else { delta_y / delta_x };
    let first_x_end = (x0 as f64 + 0.5).floor();
    let first_y_end = y0 as f64 + gradient * (first_x_end - x0 as f64);
    let first = Endpoint {
        x_pixel: first_x_end as i64,
        y_pixel: first_y_end.floor() as i64,
        y_end: first_y_end,
        x_gap: reverse_fraction_part(x0 as f64 + 0.5),
    };
    let second_x_end = (x1 as f64 + 0.5).floor();
    let second_y_end = y1 as f64 + gradient * (second_x_end - x1 as f64);
    let second = Endpoint {
        x_pixel: second_x_end as i64,
        y_pixel: second_y_end.floor() as i64,
        y_end: second_y_end,
        x_gap: fraction_part(x1 as f64 + 0.5),
    };

    let mut pixel_x = [0i64; MAX_PIXELS];
    let mut pixel_y = [0i64; MAX_PIXELS];
    let mut intensities = [0.0f64; MAX_PIXELS];
    let mut pixel_count = 0usize;
    add_endpoint(&mut pixel_x, &mut pixel_y, &mut intensities, &mut pixel_count, first, steep);
    add_endpoint(&mut pixel_x, &mut pixel_y, &mut intensities, &mut pixel_count, second, steep);

    let mut intersection_y = first.y_end + gradient;
    for x in first.x_pixel + 1..second.x_pixel {
        let y_floor = intersection_y.floor() as i64;
        let fractional = fraction_part(intersection_y);
        let complement = reverse_fraction_part(intersection_y);
        add_pixel(&mut pixel_x, &mut pixel_y, &mut intensities, &mut pixel_count,
                  x, y_floor, complement, steep);
        add_pixel(&mut pixel_x, &mut pixel_y, &mut intensities, &mut pixel_count,
                  x, y_floor + 1, fractional, steep);
        intersection_y += gradient;
    }

    let required = pixel_count * 16;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..pixel_count {
        let offset = index * 16;
        write_i32_le(output, offset, pixel_x[index]);
        write_i32_le(output, offset + 4, pixel_y[index]);
        write_f64_le(output, offset + 8, intensities[index]);
    }
    required as i64
}
