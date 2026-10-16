#[no_mangle]
pub unsafe extern "C" fn geo_location(values: *const f64, length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if values.is_null() || length != 4 { return -1; }
    let v = std::slice::from_raw_parts(values, 4);
    if v.iter().any(|value| !value.is_finite()) { return -1; }
    let (lat1d, lon1d, lat2d, lon2d) = (v[0], v[1], v[2], v[3]);
    if !(-90.0..=90.0).contains(&lat1d) || !(-90.0..=90.0).contains(&lat2d) ||
       !(-180.0..=180.0).contains(&lon1d) || !(-180.0..=180.0).contains(&lon2d) { return -1; }
    let factor = std::f64::consts::PI / 180.0;
    let (lat1, lon1, lat2, lon2) = (lat1d*factor, lon1d*factor, lat2d*factor, lon2d*factor);
    let (diff_lat, diff_lon) = (lat2-lat1, lon2-lon1);
    let (sin_lat, sin_lon) = ((diff_lat/2.0).sin(), (diff_lon/2.0).sin());
    let haversine = sin_lat*sin_lat + lat1.cos()*lat2.cos()*sin_lon*sin_lon;
    if !(0.0..=1.0).contains(&haversine) { return -1; }
    if output.is_null() || capacity < 1 { return -2; }
    *output = 6_371_010.0 * (2.0 * haversine.sqrt().atan2((1.0-haversine).sqrt()));
    1
}
