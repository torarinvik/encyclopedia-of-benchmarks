const MAX_LEVEL: i64 = 12;
const MAX_NODES: usize = (1usize << (MAX_LEVEL as usize)) - 1;
const ADDITION_PASSES: usize = 100;

#[derive(Clone, Copy)]
struct Node {
    value: i32,
    left: i32,
    right: i32,
}

fn allocate_tree(nodes: &mut [Node; MAX_NODES], used: &mut usize,
                 level: i32, lo: i32, proc_count: i32) -> i32 {
    if level == 0 || *used >= MAX_NODES { return -1; }
    let index = *used as i32;
    *used += 1;
    nodes[index as usize].value = 1;
    let left = allocate_tree(nodes, used, level - 1, lo + proc_count / 2, proc_count / 2);
    let right = allocate_tree(nodes, used, level - 1, lo, proc_count / 2);
    nodes[index as usize].left = left;
    nodes[index as usize].right = right;
    index
}

fn tree_add(nodes: &[Node; MAX_NODES], index: i32) -> i64 {
    if index < 0 { return 0; }
    let node = nodes[index as usize];
    i64::from(node.value) + tree_add(nodes, node.left) + tree_add(nodes, node.right)
}

#[no_mangle]
pub extern "C" fn treeadd(level: i64) -> i64 {
    if !(0..=MAX_LEVEL).contains(&level) { return -1; }
    let empty = Node { value: 0, left: -1, right: -1 };
    let mut nodes = [empty; MAX_NODES];
    let mut used = 0;
    let root = allocate_tree(&mut nodes, &mut used, level as i32, 0, 4);
    let mut result = 0;
    for _ in 0..ADDITION_PASSES {
        result = tree_add(&nodes, root);
    }
    result
}
