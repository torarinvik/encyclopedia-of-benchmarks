// Independent difference-product Odin draft; see package README.
// Registered draft; compilation and arithmetic output remain unverified.
package difference_product
import "core:c"

DP_PRIME :: i64(998244353)

dp_power :: proc(value, exponent_value: i64) -> i64 {
    base, exponent, result := value, exponent_value, i64(1)
    for exponent > 0 {
        if exponent & 1 != 0 { result = result * base % DP_PRIME }
        base = base * base % DP_PRIME
        exponent >>= 1
    }
    return result
}

dp_transform :: proc(values: []i64, inverse: bool) {
    n := len(values)
    reversed := 0
    for i := 1; i < n; i += 1 {
        bit := n >> 1
        for reversed & bit != 0 { reversed ~= bit; bit >>= 1 }
        reversed ~= bit
        if i < reversed { values[i], values[reversed] = values[reversed], values[i] }
    }
    for width := 2; width <= n; width *= 2 {
        step := dp_power(3, (DP_PRIME - 1) / i64(width))
        if inverse { step = dp_power(step, DP_PRIME - 2) }
        for start := 0; start < n; start += width {
            root := i64(1)
            for j := 0; j < width / 2; j += 1 {
                a := values[start + j]
                b := values[start + j + width / 2] * root % DP_PRIME
                values[start + j] = (a + b) % DP_PRIME
                values[start + j + width / 2] = (a - b + DP_PRIME) % DP_PRIME
                root = root * step % DP_PRIME
            }
        }
    }
    if inverse {
        scale := dp_power(i64(n), DP_PRIME - 2)
        for i := 0; i < n; i += 1 { values[i] = values[i] * scale % DP_PRIME }
    }
}

// Caller owns the returned slice. Temporary NTT buffers are freed here.
dp_multiply :: proc(a, b: []i64) -> []i64 {
    if len(a) == 0 || len(b) == 0 { return make([]i64, 0) }
    needed := len(a) + len(b) - 1
    result := make([]i64, needed)
    if len(a) <= 32 || len(b) <= 32 {
        for i := 0; i < len(a); i += 1 {
            for j := 0; j < len(b); j += 1 {
                result[i + j] = (result[i + j] + a[i] * b[j]) % DP_PRIME
            }
        }
        return result
    }
    size := 1
    for size < needed { size *= 2 }
    left := make([]i64, size)
    right := make([]i64, size)
    defer delete(left)
    defer delete(right)
    for i := 0; i < len(a); i += 1 { left[i] = a[i] }
    for i := 0; i < len(b); i += 1 { right[i] = b[i] }
    dp_transform(left, false)
    dp_transform(right, false)
    for i := 0; i < size; i += 1 { left[i] = left[i] * right[i] % DP_PRIME }
    dp_transform(left, true)
    for i := 0; i < needed; i += 1 { result[i] = left[i] }
    return result
}

// The returned inverse is owned by the caller; intermediates are released.
dp_inverse :: proc(poly: []i64, count: int) -> []i64 {
    inverse := make([]i64, 1)
    inverse[0] = dp_power(poly[0], DP_PRIME - 2)
    for len(inverse) < count {
        n := 2 * len(inverse)
        if n > count { n = count }
        prefix_len := len(poly)
        if prefix_len > n { prefix_len = n }
        product := dp_multiply(poly[:prefix_len], inverse)
        correction := make([]i64, n)
        for i := 0; i < n; i += 1 {
            value := i64(0)
            if i < len(product) { value = product[i] }
            correction[i] = (DP_PRIME - value) % DP_PRIME
        }
        delete(product)
        correction[0] = (correction[0] + 2) % DP_PRIME
        updated := dp_multiply(inverse, correction)
        delete(correction)
        delete(inverse)
        inverse = make([]i64, n)
        for i := 0; i < n; i += 1 { inverse[i] = updated[i] }
        delete(updated)
    }
    return inverse
}

// Divisor is a nonzero monic polynomial; caller owns the returned remainder.
dp_remainder :: proc(dividend, divisor: []i64) -> []i64 {
    if len(dividend) < len(divisor) {
        result := make([]i64, len(dividend))
        for i := 0; i < len(dividend); i += 1 { result[i] = dividend[i] }
        return result
    }
    if len(divisor) == 1 { return make([]i64, 0) }
    count := len(dividend) - len(divisor) + 1
    high := make([]i64, count)
    reversed := make([]i64, len(divisor))
    for i := 0; i < count; i += 1 { high[i] = dividend[len(dividend) - 1 - i] }
    for i := 0; i < len(divisor); i += 1 { reversed[i] = divisor[len(divisor) - 1 - i] }
    inverse := dp_inverse(reversed, count)
    delete(reversed)
    high_quotient := dp_multiply(high, inverse)
    delete(high)
    delete(inverse)
    quotient := make([]i64, count)
    for i := 0; i < count; i += 1 { quotient[i] = high_quotient[count - 1 - i] }
    delete(high_quotient)
    removed := dp_multiply(quotient, divisor)
    delete(quotient)
    provisional := make([]i64, len(divisor) - 1)
    for i := 0; i < len(provisional); i += 1 {
        provisional[i] = (dividend[i] - removed[i] + DP_PRIME) % DP_PRIME
    }
    delete(removed)
    used := len(provisional)
    for used > 0 && provisional[used - 1] == 0 { used -= 1 }
    result := make([]i64, used)
    for i := 0; i < used; i += 1 { result[i] = provisional[i] }
    delete(provisional)
    return result
}

DP_Tree :: struct {
    size, count: int,
    nodes: [][]i64,
}

dp_make_tree :: proc(points: []i64) -> DP_Tree {
    size := 1
    for size < len(points) { size *= 2 }
    tree := DP_Tree{size = size, count = len(points), nodes = make([][]i64, 2 * size)}
    for i := 0; i < size; i += 1 {
        if i < len(points) {
            tree.nodes[size + i] = make([]i64, 2)
            tree.nodes[size + i][0] = (DP_PRIME - points[i]) % DP_PRIME
            tree.nodes[size + i][1] = 1
        } else {
            tree.nodes[size + i] = make([]i64, 1)
            tree.nodes[size + i][0] = 1
        }
    }
    for node := size - 1; node > 0; node -= 1 {
        tree.nodes[node] = dp_multiply(tree.nodes[2 * node], tree.nodes[2 * node + 1])
    }
    return tree
}

dp_free_tree :: proc(tree: ^DP_Tree) {
    for node := 1; node < len(tree.nodes); node += 1 { delete(tree.nodes[node]) }
    delete(tree.nodes)
}

dp_visit :: proc(tree: ^DP_Tree, node: int, value: []i64, output: []i64) {
    if len(value) == 0 { return }
    if node >= tree.size {
        index := node - tree.size
        if index < tree.count { output[index] = value[0] }
        return
    }
    left := dp_remainder(value, tree.nodes[2 * node])
    right := dp_remainder(value, tree.nodes[2 * node + 1])
    defer delete(left)
    defer delete(right)
    dp_visit(tree, 2 * node, left, output)
    dp_visit(tree, 2 * node + 1, right, output)
}

dp_ordered :: proc(points: []i64) -> i64 {
    if len(points) <= 32 {
        product := i64(1)
        for i := 0; i < len(points); i += 1 {
            for j := i + 1; j < len(points); j += 1 {
                product = product * ((points[i] - points[j] + DP_PRIME) % DP_PRIME) % DP_PRIME
            }
        }
        return product
    }
    middle := len(points) / 2
    left, right := points[:middle], points[middle:]
    product := dp_ordered(left) * dp_ordered(right) % DP_PRIME
    if product == 0 { return 0 }
    left_tree := dp_make_tree(left)
    right_tree := dp_make_tree(right)
    defer dp_free_tree(&left_tree)
    defer dp_free_tree(&right_tree)
    root := dp_remainder(left_tree.nodes[1], right_tree.nodes[1])
    defer delete(root)
    values := make([]i64, len(right))
    defer delete(values)
    dp_visit(&right_tree, 1, root, values)
    for value in values { product = product * value % DP_PRIME }
    if len(left) & 1 != 0 && len(right) & 1 != 0 && product != 0 { product = DP_PRIME - product }
    return product
}

@(export)
difference_product :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length == 0 do return -1
    if input[0] < 0 || input[0] > 65536 do return -1
    count := int(input[0])
    if length != c.size_t(count + 1) do return -1
    points := make([]i64, count)
    defer delete(points)
    for i := 0; i < count; i += 1 {
        if input[i + 1] < 0 || input[i + 1] >= DP_PRIME do return -1
        points[i] = input[i + 1]
    }
    return dp_ordered(points)
}
