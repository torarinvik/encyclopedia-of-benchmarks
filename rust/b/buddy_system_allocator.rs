const ARENA: usize = 256;
const MAX_ORDER: usize = 8;
const MAX_OPS: usize = 64;
const MAX_IDS: usize = 32;
const MAX_INPUT_WORDS: usize = 194;
const MAX_OUTPUT_WORDS: usize = 3 * MAX_OPS + 1 + 2 * ARENA;

#[no_mangle]
pub unsafe extern "C" fn buddy_system_allocator(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > MAX_INPUT_WORDS {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    let raw_count = input[0];
    if raw_count < 0 || raw_count > MAX_OPS as i64
        || length != 1 + 3 * raw_count as usize
    {
        return -1;
    }
    let count = raw_count as usize;

    let mut free_blocks = [[false; ARENA]; MAX_ORDER + 1];
    let mut active = [false; MAX_IDS];
    let mut allocation_base = [0usize; MAX_IDS];
    let mut allocation_order = [0usize; MAX_IDS];
    let mut staged = [0i64; MAX_OUTPUT_WORDS];
    free_blocks[MAX_ORDER][0] = true;
    let mut staged_words = 0usize;

    for operation in 0..count {
        let opcode = input[1 + 3 * operation];
        let raw_id = input[2 + 3 * operation];
        let argument = input[3 + 3 * operation];
        if raw_id < 0 || raw_id >= MAX_IDS as i64 {
            return -1;
        }
        let id = raw_id as usize;
        if opcode == 0 {
            if argument < 1 || argument > ARENA as i64 || active[id] {
                return -1;
            }
            let mut target = 0usize;
            let mut rounded = 1usize;
            while rounded < argument as usize {
                rounded <<= 1;
                target += 1;
            }
            let mut found_order = MAX_ORDER + 1;
            let mut found_base = ARENA;
            for order in target..=MAX_ORDER {
                let size = 1usize << order;
                let mut base = 0usize;
                while base + size <= ARENA {
                    if free_blocks[order][base] {
                        found_order = order;
                        found_base = base;
                        break;
                    }
                    base += size;
                }
                if found_order <= MAX_ORDER {
                    break;
                }
            }
            if found_order > MAX_ORDER {
                staged[staged_words] = 0;
                staged[staged_words + 1] = -1;
                staged[staged_words + 2] = 0;
                staged_words += 3;
                continue;
            }
            free_blocks[found_order][found_base] = false;
            while found_order > target {
                found_order -= 1;
                let half = 1usize << found_order;
                free_blocks[found_order][found_base + half] = true;
            }
            active[id] = true;
            allocation_base[id] = found_base;
            allocation_order[id] = target;
            staged[staged_words] = 1;
            staged[staged_words + 1] = found_base as i64;
            staged[staged_words + 2] = (1usize << target) as i64;
            staged_words += 3;
        } else if opcode == 1 {
            if argument != 0 || !active[id] {
                return -1;
            }
            let original_base = allocation_base[id];
            let original_order = allocation_order[id];
            let original_size = 1usize << original_order;
            active[id] = false;
            let mut base = original_base;
            let mut order = original_order;
            while order < MAX_ORDER {
                let buddy = base ^ (1usize << order);
                if !free_blocks[order][buddy] {
                    break;
                }
                free_blocks[order][buddy] = false;
                if buddy < base {
                    base = buddy;
                }
                order += 1;
            }
            free_blocks[order][base] = true;
            staged[staged_words] = 1;
            staged[staged_words + 1] = original_base as i64;
            staged[staged_words + 2] = original_size as i64;
            staged_words += 3;
        } else {
            return -1;
        }
    }

    let count_index = staged_words;
    staged[staged_words] = 0;
    staged_words += 1;
    for base in 0..ARENA {
        for order in (0..=MAX_ORDER).rev() {
            if free_blocks[order][base] {
                staged[count_index] += 1;
                staged[staged_words] = base as i64;
                staged[staged_words + 1] = (1usize << order) as i64;
                staged_words += 2;
                break;
            }
        }
    }

    let required = staged_words * 8;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..staged_words {
        let word = staged[index] as u64;
        for byte in 0..8 {
            *output.add(8 * index + byte) = (word >> (8 * byte)) as u8;
        }
    }
    required as i64
}
