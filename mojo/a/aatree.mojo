from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

struct AATree:
    var keys: List[Int32]
    var left: List[Int32]
    var right: List[Int32]
    var level: List[Int32]
    var used: Int32

    fn __init__(out self):
        self.keys = List[Int32](length=256, fill=0)
        self.left = List[Int32](length=256, fill=-1)
        self.right = List[Int32](length=256, fill=-1)
        self.level = List[Int32](length=256, fill=0)
        self.used = 0

    fn node_level(self, node: Int32) -> Int32:
        if node < 0:
            return 0
        return self.level[Int(node)]

    fn skew(mut self, root: Int32) -> Int32:
        if root < 0:
            return root
        let l = self.left[Int(root)]
        if l < 0 or self.level[Int(l)] != self.level[Int(root)]:
            return root
        self.left[Int(root)] = self.right[Int(l)]
        self.right[Int(l)] = root
        return l

    fn split(mut self, root: Int32) -> Int32:
        if root < 0:
            return root
        let r = self.right[Int(root)]
        if r < 0:
            return root
        let rr = self.right[Int(r)]
        if rr < 0 or self.level[Int(root)] != self.level[Int(rr)]:
            return root
        self.right[Int(root)] = self.left[Int(r)]
        self.left[Int(r)] = root
        self.level[Int(r)] += 1
        return r

    fn contains(self, root0: Int32, key: Int32) -> Bool:
        var root = root0
        while root >= 0:
            if key < self.keys[Int(root)]:
                root = self.left[Int(root)]
            elif key > self.keys[Int(root)]:
                root = self.right[Int(root)]
            else:
                return True
        return False

    fn insert_node(mut self, root: Int32, key: Int32) -> Int32:
        if root < 0:
            let fresh = self.used
            self.used += 1
            self.keys[Int(fresh)] = key
            self.left[Int(fresh)] = -1
            self.right[Int(fresh)] = -1
            self.level[Int(fresh)] = 1
            return fresh
        if key < self.keys[Int(root)]:
            let child = self.insert_node(self.left[Int(root)], key)
            self.left[Int(root)] = child
        else:
            let child = self.insert_node(self.right[Int(root)], key)
            self.right[Int(root)] = child
        var repaired = self.skew(root)
        repaired = self.split(repaired)
        return repaired

    fn minimum_node(self, root0: Int32) -> Int32:
        var root = root0
        while self.left[Int(root)] >= 0:
            root = self.left[Int(root)]
        return root

    fn maximum_node(self, root0: Int32) -> Int32:
        var root = root0
        while self.right[Int(root)] >= 0:
            root = self.right[Int(root)]
        return root

    fn decrease_level(mut self, root: Int32) -> Int32:
        let ll = self.node_level(self.left[Int(root)])
        let rl = self.node_level(self.right[Int(root)])
        var next_level = ll
        if rl < next_level:
            next_level = rl
        next_level += 1
        if next_level < self.level[Int(root)]:
            self.level[Int(root)] = next_level
            let r = self.right[Int(root)]
            if r >= 0 and next_level < self.level[Int(r)]:
                self.level[Int(r)] = next_level
        return root

    fn remove_node(mut self, root: Int32, key: Int32) -> Int32:
        if key < self.keys[Int(root)]:
            let child = self.remove_node(self.left[Int(root)], key)
            self.left[Int(root)] = child
        elif key > self.keys[Int(root)]:
            let child = self.remove_node(self.right[Int(root)], key)
            self.right[Int(root)] = child
        elif self.left[Int(root)] < 0 and self.right[Int(root)] < 0:
            return -1
        elif self.left[Int(root)] < 0:
            let successor = self.minimum_node(self.right[Int(root)])
            let successor_key = self.keys[Int(successor)]
            self.keys[Int(root)] = successor_key
            let child = self.remove_node(self.right[Int(root)], successor_key)
            self.right[Int(root)] = child
        else:
            let predecessor = self.maximum_node(self.left[Int(root)])
            let predecessor_key = self.keys[Int(predecessor)]
            self.keys[Int(root)] = predecessor_key
            let child = self.remove_node(self.left[Int(root)], predecessor_key)
            self.left[Int(root)] = child
        var result = self.decrease_level(root)
        result = self.skew(result)
        var r = self.right[Int(result)]
        if r >= 0:
            r = self.skew(r)
            let rr = self.right[Int(r)]
            if rr >= 0:
                let fixed_rr = self.skew(rr)
                self.right[Int(r)] = fixed_rr
            self.right[Int(result)] = r
        result = self.split(result)
        r = self.right[Int(result)]
        if r >= 0:
            let fixed = self.split(r)
            self.right[Int(result)] = fixed
        return result

fn write_i32(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int32):
    let bits = UInt32(value)
    output[offset] = UInt8(bits & 255)
    output[offset + 1] = UInt8((bits >> 8) & 255)
    output[offset + 2] = UInt8((bits >> 16) & 255)
    output[offset + 3] = UInt8((bits >> 24) & 255)

@export("aatree")
fn aatree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or input[0] < 0 or input[0] > 256:
        return -1
    let count = Int(input[0])
    if length != c_size_t(1 + 2 * count):
        return -1
    let output_bytes = 4 * count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)):
        return -2
    var tree = AATree()
    var root: Int32 = -1
    var size: Int32 = 0
    var results = List[Int32](length=count, fill=0)
    for op in range(count):
        let opcode = input[1 + 2 * op]
        let raw = input[2 + 2 * op]
        if opcode < 0 or opcode > 4:
            return -1
        if opcode <= 2 and (raw < -2147483648 or raw > 2147483647):
            return -1
        if opcode >= 3 and raw != 0:
            return -1
        let key = Int32(raw)
        if opcode == 0:
            if tree.contains(root, key):
                return -1
            root = tree.insert_node(root, key)
            size += 1
            results[op] = size
        elif opcode == 1:
            if not tree.contains(root, key):
                return -1
            root = tree.remove_node(root, key)
            size -= 1
            results[op] = size
        elif opcode == 2:
            if tree.contains(root, key):
                results[op] = 1
            else:
                results[op] = 0
        elif root < 0:
            return -1
        elif opcode == 3:
            results[op] = tree.keys[Int(tree.minimum_node(root))]
        else:
            results[op] = tree.keys[Int(tree.maximum_node(root))]
    for op in range(count):
        write_i32(output, 4 * op, results[op])
    return Int64(output_bytes)
