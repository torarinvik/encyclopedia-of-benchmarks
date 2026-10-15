const MAX_DIMS: usize = 65;
const MAX_DIMENSION: i64 = 1000;
const MAX_CELLS: usize = MAX_DIMS * MAX_DIMS;

#[no_mangle]
pub unsafe extern "C" fn matrix_chain_multiplication(dimensions: *const i64, length: usize) -> i64 {
    if length > MAX_DIMS { return -1; }
    for index in 0..length {
        let dimension = *dimensions.add(index);
        if dimension < 1 || dimension > MAX_DIMENSION { return -1; }
    }
    if length < 2 { return 0; }

    let matrix_count = length - 1;
    let mut costs = [0_i64; MAX_CELLS];
    for chain_length in 2..=matrix_count {
        for start in 0..=matrix_count - chain_length {
            let finish = start + chain_length - 1;
            let mut best = i64::MAX;
            for split in start..finish {
                let cost = costs[start * MAX_DIMS + split]
                    + costs[(split + 1) * MAX_DIMS + finish]
                    + *dimensions.add(start)
                        * *dimensions.add(split + 1)
                        * *dimensions.add(finish + 1);
                if cost < best { best = cost; }
            }
            costs[start * MAX_DIMS + finish] = best;
        }
    }
    costs[matrix_count - 1]
}
