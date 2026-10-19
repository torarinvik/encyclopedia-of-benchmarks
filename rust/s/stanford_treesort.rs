const MIN_RUNS: i64 = 1;
const MAX_RUNS: i64 = 100;
const ELEMENT_COUNT: usize = 5000;
const MAX_OUTPUT_BYTES: usize = 700;
#[derive(Clone, Copy, Default)]
struct TreeNode { value: i32, left: i32, right: i32 }

fn next_random(seed: &mut i64) -> i32 {
    *seed = (*seed * 1309 + 13849) & 65535;
    *seed as i32
}
fn validate_tree(nodes: &[TreeNode; ELEMENT_COUNT], root: usize) -> bool {
    let node = nodes[root];
    if node.left != -1 {
        let child = nodes[node.left as usize];
        if child.value <= node.value || !validate_tree(nodes, node.left as usize) { return false; }
    }
    if node.right != -1 {
        let child = nodes[node.right as usize];
        if child.value >= node.value || !validate_tree(nodes, node.right as usize) { return false; }
    }
    true
}
fn build_and_check_pass(selected_run: usize) -> (i32, bool) {
    let mut values = [0_i32; ELEMENT_COUNT];
    let mut nodes = [TreeNode::default(); ELEMENT_COUNT];
    let mut seed = 74755_i64;
    for value in values.iter_mut() {
        let temp = next_random(&mut seed);
        *value = temp - (temp / 100000) * 100000 - 50000;
    }
    nodes[0] = TreeNode { value: values[0], left: -1, right: -1 };
    let mut used = 1_usize;
    for index in 1..ELEMENT_COUNT {
        let mut current = 0_usize;
        loop {
            let go_left = if values[index] > nodes[current].value { true }
                else if values[index] < nodes[current].value { false }
                else { break; };
            let child = if go_left { nodes[current].left } else { nodes[current].right };
            if child == -1 {
                if go_left { nodes[current].left = used as i32; }
                else { nodes[current].right = used as i32; }
                nodes[used] = TreeNode { value: values[index], left: -1, right: -1 };
                used += 1;
                break;
            }
            current = child as usize;
        }
    }
    (values[selected_run + 1], validate_tree(&nodes, 0))
}
fn append_text(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, text: &[u8]) {
    for &byte in text { buffer[*used] = byte; *used += 1; }
}
fn append_integer(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, value: i32) {
    let mut remaining = value;
    if remaining < 0 { buffer[*used] = b'-'; *used += 1; remaining = -remaining; }
    let mut reverse = [0_u8; 12]; let mut count = 0;
    loop { reverse[count] = b'0' + (remaining % 10) as u8; count += 1; remaining /= 10; if remaining == 0 { break; } }
    while count > 0 { count -= 1; buffer[*used] = reverse[count]; *used += 1; }
}

#[no_mangle]
pub unsafe extern "C" fn stanford_treesort(runs: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(MIN_RUNS..=MAX_RUNS).contains(&runs) { return -1; }
    if output.is_null() { return -2; }
    let mut staged = [0_u8; MAX_OUTPUT_BYTES]; let mut used = 0;
    for run in 0..runs as usize {
        let (value, valid) = build_and_check_pass(run);
        append_integer(&mut staged, &mut used, value); append_text(&mut staged, &mut used, b"\n");
        if !valid { append_text(&mut staged, &mut used, b" Error in Tree.\n"); }
    }
    if output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
