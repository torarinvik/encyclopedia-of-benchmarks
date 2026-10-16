const MAX_NODES: usize = 64;
const MAX_INPUT_LENGTH: usize = 67;

#[no_mangle]
pub unsafe extern "C" fn inorder_successor_of_bst(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let (count_value, target) = (input[0], input[1]);
    if !(0..=MAX_NODES as i64).contains(&count_value)
        || !(1..=2_147_483_647).contains(&target)
        || length != count_value as usize + 2
    {
        return -1;
    }

    let count = count_value as usize;
    let mut keys = [0_i64; MAX_NODES];
    let mut left = [-1_isize; MAX_NODES];
    let mut right = [-1_isize; MAX_NODES];
    for index in 0..count {
        let key = input[index + 2];
        if !(1..=2_147_483_647).contains(&key) || keys[..index].contains(&key) {
            return -1;
        }
        keys[index] = key;
    }

    let mut root = -1_isize;
    for index in 0..count {
        if root < 0 {
            root = index as isize;
            continue;
        }
        let mut current = root as usize;
        loop {
            if keys[index] <= keys[current] {
                if left[current] < 0 {
                    left[current] = index as isize;
                    break;
                }
                current = left[current] as usize;
            } else {
                if right[current] < 0 {
                    right[current] = index as isize;
                    break;
                }
                current = right[current] as usize;
            }
        }
    }

    let mut current = root;
    while current >= 0 && keys[current as usize] != target {
        let index = current as usize;
        current = if target > keys[index] { right[index] } else { left[index] };
    }
    if current < 0 {
        return 0;
    }
    let current_index = current as usize;
    if right[current_index] >= 0 {
        let mut successor = right[current_index] as usize;
        while left[successor] >= 0 {
            successor = left[successor] as usize;
        }
        return keys[successor];
    }

    let mut successor = -1_isize;
    let mut ancestor = root;
    while ancestor >= 0 && ancestor != current {
        let index = ancestor as usize;
        if keys[current_index] < keys[index] {
            successor = ancestor;
            ancestor = left[index];
        } else {
            ancestor = right[index];
        }
    }
    if successor < 0 { 0 } else { keys[successor as usize] }
}
