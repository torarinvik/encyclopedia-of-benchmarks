const MAX_PROCESSES: usize = 16;
const MAX_RESOURCES: usize = 8;

/// Check whether the process/resource state has a safe completion order.
#[no_mangle]
pub unsafe extern "C" fn bankers_algorithm(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 5 || length > 266 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let process_value = values[0];
    let resource_value = values[1];
    if !(1..=MAX_PROCESSES as i64).contains(&process_value)
        || !(1..=MAX_RESOURCES as i64).contains(&resource_value)
    {
        return -1;
    }
    let processes = process_value as usize;
    let resources = resource_value as usize;
    let maximum_offset = 2 + resources;
    let allocation_offset = maximum_offset + processes * resources;
    if length != allocation_offset + processes * resources {
        return -1;
    }
    let mut work = [0i64; MAX_RESOURCES];
    for resource in 0..resources {
        let available = values[2 + resource];
        if !(0..=100).contains(&available) {
            return -1;
        }
        work[resource] = available;
    }
    for process in 0..processes {
        for resource in 0..resources {
            let index = process * resources + resource;
            let maximum = values[maximum_offset + index];
            let allocation = values[allocation_offset + index];
            if !(0..=100).contains(&maximum) || allocation < 0 || allocation > maximum {
                return -1;
            }
        }
    }

    let mut finished = [false; MAX_PROCESSES];
    let mut completed = 0;
    while completed < processes {
        let mut progress = false;
        for process in 0..processes {
            if finished[process] {
                continue;
            }
            let feasible = (0..resources).all(|resource| {
                let index = process * resources + resource;
                values[maximum_offset + index] - values[allocation_offset + index] <= work[resource]
            });
            if feasible {
                for resource in 0..resources {
                    work[resource] += values[allocation_offset + process * resources + resource];
                }
                finished[process] = true;
                completed += 1;
                progress = true;
            }
        }
        if !progress {
            return 0;
        }
    }
    1
}
