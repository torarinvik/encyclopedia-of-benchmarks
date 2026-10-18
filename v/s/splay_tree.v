module splay_tree

const max_ops = 64
const max_keys = 32
const max_input = 130
const max_output = 784

struct Node {
mut:
    key i32
    left int
    right int
}

fn rotate_right(mut nodes &Node, root int) int {
    unsafe {
        child := nodes[root].left
        nodes[root].left = nodes[child].right
        nodes[child].right = root
        return child
    }
}
fn rotate_left(mut nodes &Node, root int) int {
    unsafe {
        child := nodes[root].right
        nodes[root].right = nodes[child].left
        nodes[child].left = root
        return child
    }
}
fn splay(mut nodes &Node, root int, key i32) int {
    unsafe {
        if root < 0 || nodes[root].key == key { return root }
        if key < nodes[root].key {
            left := nodes[root].left
            if left < 0 { return root }
            if key < nodes[left].key {
                nodes[left].left = splay(mut nodes, nodes[left].left, key)
                root = rotate_right(mut nodes, root)
            } else if key > nodes[left].key {
                nodes[left].right = splay(mut nodes, nodes[left].right, key)
                if nodes[left].right >= 0 { nodes[root].left = rotate_left(mut nodes, left) }
            }
            if nodes[root].left < 0 { return root }
            return rotate_right(mut nodes, root)
        }
        right := nodes[root].right
        if right < 0 { return root }
        if key > nodes[right].key {
            nodes[right].right = splay(mut nodes, nodes[right].right, key)
            root = rotate_left(mut nodes, root)
        } else if key < nodes[right].key {
            nodes[right].left = splay(mut nodes, nodes[right].left, key)
            if nodes[right].left >= 0 { nodes[root].right = rotate_right(mut nodes, right) }
        }
        if nodes[root].right < 0 { return root }
        return rotate_left(mut nodes, root)
    }
}
fn inorder(nodes &Node, root int, mut keys &i64, mut count &int) {
    unsafe {
        if root < 0 { return }
        inorder(nodes, nodes[root].left, mut keys, mut count)
        keys[count] = i64(nodes[root].key)
        count++
        inorder(nodes, nodes[root].right, mut keys, mut count)
    }
}
fn put_i64_le(mut output &u8, offset int, value i64) {
    bits := u64(value)
    unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}

@[export: 'splay_tree']
pub fn splay_tree(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || input_length == 0 || input_length > max_input || input[0] < 0 || input[0] > max_ops { return -1 }
        op_count := int(input[0])
        if int(input_length) != 1 + 2 * op_count { return -1 }
        mut ops := [max_ops]i64{}
        mut keys := [max_ops]i64{}
        mut tags := [max_ops]i64{}
        mut live := [max_keys]i64{}
        mut live_count := 0
        mut offset := 1
        for i in 0 .. op_count {
            op := input[offset]
            key := input[offset + 1]
            offset += 2
            if (op != 0 && op != 1 && op != 2) || key < -2147483648 || key > 2147483647 { return -1 }
            ops[i] = op
            keys[i] = key
            mut found := live_count
            for j in 0 .. live_count { if live[j] == key { found = j; break } }
            if op == 0 {
                if found < live_count || live_count == max_keys { return -1 }
                live[live_count] = key
                live_count++
            } else if op == 2 {
                if live_count == 0 { return -1 }
                if found < live_count { live_count--; live[found] = live[live_count] }
            }
        }
        mut nodes := [max_ops]Node{}
        mut node_count := 0
        mut root := -1
        for i in 0 .. op_count {
            key := i32(keys[i])
            if ops[i] == 0 {
                if root < 0 {
                    nodes[node_count] = Node{key, -1, -1}
                    root = node_count
                    node_count++
                } else {
                    root = splay(mut nodes[0], root, key)
                    nodes[node_count] = Node{key, -1, -1}
                    fresh := node_count
                    node_count++
                    if key < nodes[root].key {
                        nodes[fresh].left = nodes[root].left
                        nodes[fresh].right = root
                        nodes[root].left = -1
                    } else {
                        nodes[fresh].right = nodes[root].right
                        nodes[fresh].left = root
                        nodes[root].right = -1
                    }
                    root = fresh
                }
                tags[i] = -2
            } else if ops[i] == 1 {
                root = splay(mut nodes[0], root, key)
                tags[i] = if root >= 0 && nodes[root].key == key { i64(1) } else { i64(0) }
            } else {
                root = splay(mut nodes[0], root, key)
                tags[i] = -3
                if nodes[root].key == key {
                    left := nodes[root].left
                    right := nodes[root].right
                    if left < 0 { root = right } else { root = splay(mut nodes[0], left, key); nodes[root].right = right }
                }
            }
        }
        mut final_keys := [max_keys]i64{}
        mut final_count := 0
        inorder(nodes[0], root, mut final_keys[0], mut final_count)
        mut staged := [max_output]u8{}
        mut written := 0
        put_i64_le(mut staged[0], written, i64(op_count))
        written += 8
        for i in 0 .. op_count { put_i64_le(mut staged[0], written, tags[i]); written += 8 }
        put_i64_le(mut staged[0], written, i64(final_count))
        written += 8
        for i in 0 .. final_count { put_i64_le(mut staged[0], written, final_keys[i]); written += 8 }
        if output == nil || capacity < written { return -2 }
        for i in 0 .. written { output[i] = staged[i] }
        return i64(written)
    }
}
