const MAX_NODES: usize = 128;

#[derive(Clone, Copy)]
struct Node {
    key: i32,
    left: i32,
    right: i32,
    left_is_thread: bool,
    right_is_thread: bool,
}

const EMPTY: Node = Node {
    key: 0,
    left: -1,
    right: -1,
    left_is_thread: false,
    right_is_thread: false,
};

unsafe fn put_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn threaded_binary_tree(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_NODES as i64 {
        return -1;
    }
    let count = values[0] as usize;
    if length != 1 + count {
        return -1;
    }
    for &key in &values[1..] {
        if key < i32::MIN as i64 || key > i32::MAX as i64 {
            return -1;
        }
    }

    let required = count * 4;
    if required > 0 && (output.is_null() || output_capacity < required) {
        return -2;
    }

    let mut nodes = [EMPTY; MAX_NODES];
    let mut root: i32 = -1;
    for inserted in 0..count {
        let node = inserted as i32;
        let key = values[inserted + 1] as i32;
        nodes[inserted] = Node { key, ..EMPTY };
        if root == -1 {
            root = node;
            continue;
        }

        let mut current = root;
        let parent = loop {
            let parent = current;
            let at = current as usize;
            if key < nodes[at].key {
                if !nodes[at].left_is_thread && nodes[at].left != -1 {
                    current = nodes[at].left;
                } else {
                    break parent;
                }
            } else if !nodes[at].right_is_thread && nodes[at].right != -1 {
                current = nodes[at].right;
            } else {
                break parent;
            }
        };

        let parent_index = parent as usize;
        if key < nodes[parent_index].key {
            nodes[inserted].left = nodes[parent_index].left;
            nodes[inserted].left_is_thread = nodes[parent_index].left_is_thread;
            nodes[inserted].right = parent;
            nodes[inserted].right_is_thread = true;
            nodes[parent_index].left = node;
            nodes[parent_index].left_is_thread = false;
        } else {
            nodes[inserted].right = nodes[parent_index].right;
            nodes[inserted].right_is_thread = nodes[parent_index].right_is_thread;
            nodes[inserted].left = parent;
            nodes[inserted].left_is_thread = true;
            nodes[parent_index].right = node;
            nodes[parent_index].right_is_thread = false;
        }
    }

    let mut current = root;
    while current != -1 {
        let at = current as usize;
        if nodes[at].left_is_thread || nodes[at].left == -1 {
            break;
        }
        current = nodes[at].left;
    }
    let mut written = 0;
    while current != -1 {
        let at = current as usize;
        put_i32_le(output, written, nodes[at].key);
        written += 4;
        if nodes[at].right_is_thread {
            current = nodes[at].right;
        } else {
            current = nodes[at].right;
            while current != -1 {
                let next = current as usize;
                if nodes[next].left_is_thread || nodes[next].left == -1 {
                    break;
                }
                current = nodes[next].left;
            }
        }
    }
    written as i64
}
