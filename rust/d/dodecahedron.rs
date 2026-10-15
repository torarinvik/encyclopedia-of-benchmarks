/// Compute a regular dodecahedron's area or volume from its edge length.
#[no_mangle]
pub extern "C" fn dodecahedron(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let edge = unsafe { *values };
    let quantity = unsafe { *values.add(1) };
    if !(1..=1_000_000).contains(&edge) || (quantity != 0 && quantity != 1) { return -1.0e300; }

    let root_five = 5.0_f64.sqrt();
    if quantity == 0 {
        let area_factor = 3.0 * (25.0 + 10.0 * root_five).sqrt();
        return area_factor * (edge * edge) as f64;
    }
    let volume_factor = (15.0 + 7.0 * root_five) / 4.0;
    volume_factor * (edge * edge * edge) as f64
}
