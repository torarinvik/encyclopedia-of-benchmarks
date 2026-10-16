/// Count square-grid lattice paths as the central binomial coefficient C(2n, n).
#[no_mangle]
pub extern "C" fn problem15(grid_size: i64) -> i64 {
    if !(0..=20).contains(&grid_size) {
        return -1;
    }
    let mut paths = 1i64;
    for step in 1..=grid_size {
        paths = paths * (grid_size + step) / step;
    }
    paths
}
