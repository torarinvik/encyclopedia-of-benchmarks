# Independent difference-product Mojo draft; see package README.
# Registered draft; compilation and arithmetic output remain unverified.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime DP_PRIME = Int64(998244353)

fn dp_power(value: Int64, power_value: Int64) -> Int64:
    var base = value
    var exponent = power_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = (result * base) % DP_PRIME
        base = (base * base) % DP_PRIME
        exponent >>= 1
    return result

fn dp_transform(mut values: List[Int64], inverse: Bool):
    let n = len(values)
    var reversed = 0
    for i in range(1, n):
        var bit = n >> 1
        while (reversed & bit) != 0:
            reversed ^= bit
            bit >>= 1
        reversed ^= bit
        if i < reversed:
            let temporary = values[i]
            values[i] = values[reversed]
            values[reversed] = temporary
    var width = 2
    while width <= n:
        var step = dp_power(3, (DP_PRIME - 1) // Int64(width))
        if inverse: step = dp_power(step, DP_PRIME - 2)
        var start = 0
        while start < n:
            var root: Int64 = 1
            for j in range(width // 2):
                let a = values[start + j]
                let b = (values[start + j + width // 2] * root) % DP_PRIME
                values[start + j] = (a + b) % DP_PRIME
                values[start + j + width // 2] = (a - b + DP_PRIME) % DP_PRIME
                root = (root * step) % DP_PRIME
            start += width
        width *= 2
    if inverse:
        let scale = dp_power(Int64(n), DP_PRIME - 2)
        for i in range(n): values[i] = (values[i] * scale) % DP_PRIME

fn dp_multiply(a: List[Int64], b: List[Int64]) -> List[Int64]:
    if len(a) == 0 or len(b) == 0: return List[Int64]()
    let needed = len(a) + len(b) - 1
    if len(a) <= 32 or len(b) <= 32:
        var output = List[Int64](length=needed, fill=0)
        for i in range(len(a)):
            for j in range(len(b)):
                output[i + j] = (output[i + j] + a[i] * b[j]) % DP_PRIME
        return output^
    var size = 1
    while size < needed: size *= 2
    var left = List[Int64](length=size, fill=0)
    var right = List[Int64](length=size, fill=0)
    for i in range(len(a)): left[i] = a[i]
    for i in range(len(b)): right[i] = b[i]
    dp_transform(left, False)
    dp_transform(right, False)
    for i in range(size): left[i] = (left[i] * right[i]) % DP_PRIME
    dp_transform(left, True)
    var output = List[Int64](length=needed, fill=0)
    for i in range(needed): output[i] = left[i]
    return output^

fn dp_inverse(poly: List[Int64], count: Int) -> List[Int64]:
    var inverse = List[Int64](length=1, fill=dp_power(poly[0], DP_PRIME - 2))
    while len(inverse) < count:
        var n = 2 * len(inverse)
        if n > count: n = count
        var prefix_length = len(poly)
        if prefix_length > n: prefix_length = n
        var prefix = List[Int64](length=prefix_length, fill=0)
        for i in range(prefix_length): prefix[i] = poly[i]
        let product = dp_multiply(prefix, inverse)
        var correction = List[Int64](length=n, fill=0)
        for i in range(n):
            if i < len(product): correction[i] = (DP_PRIME - product[i]) % DP_PRIME
        correction[0] = (correction[0] + 2) % DP_PRIME
        let updated = dp_multiply(inverse, correction)
        var next = List[Int64](length=n, fill=0)
        for i in range(n): next[i] = updated[i]
        inverse = next^
    return inverse^

fn dp_remainder(dividend: List[Int64], divisor: List[Int64]) -> List[Int64]:
    if len(dividend) < len(divisor):
        var result = List[Int64](length=len(dividend), fill=0)
        for i in range(len(dividend)): result[i] = dividend[i]
        return result^
    if len(divisor) == 1: return List[Int64]()
    let count = len(dividend) - len(divisor) + 1
    var high = List[Int64](length=count, fill=0)
    var reversed = List[Int64](length=len(divisor), fill=0)
    for i in range(count): high[i] = dividend[len(dividend) - 1 - i]
    for i in range(len(divisor)): reversed[i] = divisor[len(divisor) - 1 - i]
    let reciprocal = dp_inverse(reversed, count)
    let high_quotient = dp_multiply(high, reciprocal)
    var quotient = List[Int64](length=count, fill=0)
    for i in range(count): quotient[i] = high_quotient[count - 1 - i]
    let removed = dp_multiply(quotient, divisor)
    var result = List[Int64](length=len(divisor) - 1, fill=0)
    for i in range(len(result)):
        result[i] = (dividend[i] - removed[i] + DP_PRIME) % DP_PRIME
    while len(result) > 0 and result[len(result) - 1] == 0:
        _ = result.pop()
    return result^

fn dp_tree(points: List[Int64], size: Int) -> List[List[Int64]]:
    var nodes = List[List[Int64]](capacity=2 * size)
    for _ in range(2 * size): nodes.append(List[Int64]())
    for i in range(size):
        var leaf = List[Int64]()
        if i < len(points):
            leaf.append((DP_PRIME - points[i]) % DP_PRIME)
            leaf.append(1)
        else:
            leaf.append(1)
        nodes[size + i] = leaf^
    var index = size - 1
    while index > 0:
        nodes[index] = dp_multiply(nodes[2 * index], nodes[2 * index + 1])
        index -= 1
    return nodes^

fn dp_visit(nodes: List[List[Int64]], size: Int, count: Int, node: Int,
            value: List[Int64], mut output: List[Int64]):
    if len(value) == 0: return
    if node >= size:
        let index = node - size
        if index < count: output[index] = value[0]
        return
    let left = dp_remainder(value, nodes[2 * node])
    let right = dp_remainder(value, nodes[2 * node + 1])
    dp_visit(nodes, size, count, 2 * node, left, output)
    dp_visit(nodes, size, count, 2 * node + 1, right, output)

fn dp_ordered(points: List[Int64], begin: Int, end: Int) -> Int64:
    let count = end - begin
    if count <= 32:
        var result: Int64 = 1
        for i in range(begin, end):
            for j in range(i + 1, end):
                result = (result * ((points[i] - points[j] + DP_PRIME) % DP_PRIME)) % DP_PRIME
        return result
    let middle = begin + count // 2
    var result = (dp_ordered(points, begin, middle) * dp_ordered(points, middle, end)) % DP_PRIME
    if result == 0: return 0
    var left = List[Int64](capacity=middle - begin)
    var right = List[Int64](capacity=end - middle)
    for i in range(begin, middle): left.append(points[i])
    for i in range(middle, end): right.append(points[i])
    var left_size = 1
    var right_size = 1
    while left_size < len(left): left_size *= 2
    while right_size < len(right): right_size *= 2
    let left_tree = dp_tree(left, left_size)
    let right_tree = dp_tree(right, right_size)
    let root = dp_remainder(left_tree[1], right_tree[1])
    var values = List[Int64](length=len(right), fill=0)
    dp_visit(right_tree, right_size, len(right), 1, root, values)
    for value in values: result = (result * value) % DP_PRIME
    if (len(left) & 1) != 0 and (len(right) & 1) != 0 and result != 0:
        result = DP_PRIME - result
    return result

@export("difference_product")
fn difference_product(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0: return -1
    if input[0] < 0 or input[0] > 65536: return -1
    let count = Int(input[0])
    if length != c_size_t(count + 1): return -1
    var points = List[Int64](capacity=count)
    for i in range(count):
        if input[i + 1] < 0 or input[i + 1] >= DP_PRIME: return -1
        points.append(input[i + 1])
    return dp_ordered(points, 0, count)
