const MAX_ROOT: usize = 444;
const MAX_PARSEABLE_LENGTH: usize = 2;

#[derive(Clone, Copy, Default)]
struct Node {
    sum: i32,
    a: i32,
    b: i32,
}

fn less_node(left: Node, right: Node) -> bool {
    if left.sum != right.sum { return left.sum < right.sum; }
    if left.a != right.a { return left.a < right.a; }
    left.b < right.b
}

fn push(heap: &mut [Node; MAX_ROOT], size: &mut usize, node: Node) {
    let mut index = *size;
    *size += 1;
    while index > 0 {
        let parent = (index - 1) / 2;
        if !less_node(node, heap[parent]) { break; }
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

fn pop(heap: &mut [Node; MAX_ROOT], size: &mut usize) -> Node {
    let result = heap[0];
    *size -= 1;
    if *size == 0 { return result; }
    let last = heap[*size];
    let mut index = 0;
    while 2 * index + 1 < *size {
        let mut child = 2 * index + 1;
        if child + 1 < *size && less_node(heap[child + 1], heap[child]) { child += 1; }
        if !less_node(heap[child], last) { break; }
        heap[index] = heap[child];
        index = child;
    }
    heap[index] = last;
    result
}

fn cube(value: i32) -> i32 { value * value * value }

fn search(ways: i32) -> i64 {
    let mut heap = [Node::default(); MAX_ROOT];
    let mut size = 0;
    for a in 1..=MAX_ROOT as i32 {
        let root = a;
        let value = cube(root);
        push(&mut heap, &mut size, Node { sum: 2 * value, a: root, b: root });
    }
    while size > 0 {
        let first = pop(&mut heap, &mut size);
        let total = first.sum;
        let mut count = 1;
        if first.b < MAX_ROOT as i32 {
            let next_b = first.b + 1;
            push(&mut heap, &mut size, Node { sum: cube(first.a) + cube(next_b), a: first.a, b: next_b });
        }
        while size > 0 && heap[0].sum == total {
            let equal = pop(&mut heap, &mut size);
            count += 1;
            if equal.b < MAX_ROOT as i32 {
                let next_b = equal.b + 1;
                push(&mut heap, &mut size, Node { sum: cube(equal.a) + cube(next_b), a: equal.a, b: next_b });
            }
        }
        if count >= ways { return i64::from(total); }
    }
    -1
}

#[no_mangle]
pub unsafe extern "C" fn taxicab_number_minimum_representations(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    if length != 1 { return -1; }
    let ways = *input;
    if ways != 2 && ways != 3 { return -1; }
    search(ways as i32)
}
