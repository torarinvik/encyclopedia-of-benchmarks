// Independent difference-product C3 draft; see package README.
// Registered draft; compilation and arithmetic output remain unverified.
module difference_product;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);
const long DP_PRIME = 998244353;

fn long dp_power(long value, long power_value) {
    long base = value, exponent = power_value, result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % DP_PRIME;
        base = base * base % DP_PRIME;
        exponent >>= 1;
    }
    return result;
}

fn void dp_transform(long* values, usz count, bool inverse) {
    usz reversed = 0;
    for (usz i = 1; i < count; i++) {
        usz bit = count >> 1;
        while ((reversed & bit) != 0) { reversed ^= bit; bit >>= 1; }
        reversed ^= bit;
        if (i < reversed) { long temporary = values[i]; values[i] = values[reversed]; values[reversed] = temporary; }
    }
    for (usz width = 2; width <= count; width *= 2) {
        long step = dp_power(3, (DP_PRIME - 1) / (long)width);
        if (inverse) step = dp_power(step, DP_PRIME - 2);
        for (usz start = 0; start < count; start += width) {
            long root = 1;
            for (usz j = 0; j < width / 2; j++) {
                long even = values[start + j];
                long odd = values[start + j + width / 2] * root % DP_PRIME;
                values[start + j] = (even + odd) % DP_PRIME;
                values[start + j + width / 2] = (even - odd + DP_PRIME) % DP_PRIME;
                root = root * step % DP_PRIME;
            }
        }
    }
    if (inverse) {
        long scale = dp_power((long)count, DP_PRIME - 2);
        for (usz i = 0; i < count; i++) values[i] = values[i] * scale % DP_PRIME;
    }
}

// Returns an owned buffer and its logical length; failure is recorded in ok.
fn long* dp_allocate(usz count, bool* ok) {
    if (!*ok) return null;
    long* result = (long*)calloc(count == 0 ? 1 : count, sizeof(long));
    if (result == null) *ok = false;
    return result;
}

fn long* dp_multiply(long* a, usz an, long* b, usz bn, usz* out_len, bool* ok) {
    if (!*ok) { *out_len = 0; return null; }
    if (an == 0 || bn == 0) { *out_len = 0; return dp_allocate(0, ok); }
    usz needed = an + bn - 1;
    *out_len = needed;
    long* result = dp_allocate(needed, ok);
    if (!*ok) return null;
    if (an <= 32 || bn <= 32) {
        for (usz i = 0; i < an; i++)
            for (usz j = 0; j < bn; j++) result[i + j] = (result[i + j] + a[i] * b[j]) % DP_PRIME;
        return result;
    }
    usz size = 1;
    while (size < needed) size *= 2;
    long* left = dp_allocate(size, ok);
    long* right = dp_allocate(size, ok);
    if (!*ok) { free(result); free(left); free(right); return null; }
    for (usz i = 0; i < an; i++) left[i] = a[i];
    for (usz i = 0; i < bn; i++) right[i] = b[i];
    dp_transform(left, size, false);
    dp_transform(right, size, false);
    for (usz i = 0; i < size; i++) left[i] = left[i] * right[i] % DP_PRIME;
    dp_transform(left, size, true);
    for (usz i = 0; i < needed; i++) result[i] = left[i];
    free(left); free(right);
    return result;
}

// The caller owns the inverse; each Newton step releases its temporaries.
fn long* dp_inverse(long* input, usz input_len, usz count, bool* ok) {
    long* inverse = dp_allocate(1, ok);
    if (!*ok) return null;
    inverse[0] = dp_power(input[0], DP_PRIME - 2);
    usz length = 1;
    while (*ok && length < count) {
        usz next = 2 * length;
        if (next > count) next = count;
        usz prefix = input_len < next ? input_len : next;
        usz product_len = 0;
        long* product = dp_multiply(input, prefix, inverse, length, &product_len, ok);
        long* correction = dp_allocate(next, ok);
        if (*ok) {
            for (usz i = 0; i < next; i++) {
                long value = i < product_len ? product[i] : 0;
                correction[i] = (DP_PRIME - value) % DP_PRIME;
            }
            correction[0] = (correction[0] + 2) % DP_PRIME;
        }
        free(product);
        usz updated_len = 0;
        long* updated = dp_multiply(inverse, length, correction, next, &updated_len, ok);
        free(correction);
        free(inverse);
        if (!*ok) { free(updated); return null; }
        inverse = updated;
        length = next;
    }
    return inverse;
}

// Divisor is nonzero and monic. Returned buffer is owned by the caller.
fn long* dp_remainder(long* dividend, usz an, long* divisor, usz bn, usz* out_len, bool* ok) {
    if (!*ok) { *out_len = 0; return null; }
    if (an < bn) {
        *out_len = an;
        long* result = dp_allocate(an, ok);
        if (*ok) for (usz i = 0; i < an; i++) result[i] = dividend[i];
        return result;
    }
    if (bn == 1) { *out_len = 0; return dp_allocate(0, ok); }
    usz count = an - bn + 1;
    long* high = dp_allocate(count, ok);
    long* reversed = dp_allocate(bn, ok);
    if (*ok) {
        for (usz i = 0; i < count; i++) high[i] = dividend[an - 1 - i];
        for (usz i = 0; i < bn; i++) reversed[i] = divisor[bn - 1 - i];
    }
    long* inverse = *ok ? dp_inverse(reversed, bn, count, ok) : null;
    free(reversed);
    usz high_len = 0;
    long* high_quotient = dp_multiply(high, count, inverse, count, &high_len, ok);
    free(high); free(inverse);
    long* quotient = dp_allocate(count, ok);
    if (*ok) for (usz i = 0; i < count; i++) quotient[i] = high_quotient[count - 1 - i];
    free(high_quotient);
    usz removed_len = 0;
    long* removed = dp_multiply(quotient, count, divisor, bn, &removed_len, ok);
    free(quotient);
    long* result = dp_allocate(bn - 1, ok);
    if (*ok) {
        for (usz i = 0; i < bn - 1; i++) {
            long part = i < removed_len ? removed[i] : 0;
            result[i] = (dividend[i] - part + DP_PRIME) % DP_PRIME;
        }
        *out_len = bn - 1;
        while (*out_len > 0 && result[*out_len - 1] == 0) *out_len -= 1;
    } else {
        *out_len = 0;
    }
    free(removed);
    if (!*ok) { free(result); return null; }
    return result;
}

struct DPPoly { long* coefficients; usz length; }
struct DPTree { usz size; usz count; DPPoly* nodes; }

fn void dp_tree_free(DPTree* tree) {
    if (tree.nodes != null) {
        for (usz i = 0; i < 2 * tree.size; i++) free(tree.nodes[i].coefficients);
        free(tree.nodes);
        tree.nodes = null;
    }
}

fn void dp_tree_init(DPTree* tree, long* points, usz count, bool* ok) {
    tree.size = 1;
    tree.count = count;
    tree.nodes = null;
    while (tree.size < count) tree.size *= 2;
    if (!*ok) return;
    tree.nodes = (DPPoly*)calloc(2 * tree.size, sizeof(DPPoly));
    if (tree.nodes == null) { *ok = false; return; }
    for (usz i = 0; i < tree.size && *ok; i++) {
        usz slot = tree.size + i;
        tree.nodes[slot].length = i < count ? 2 : 1;
        tree.nodes[slot].coefficients = dp_allocate(tree.nodes[slot].length, ok);
        if (*ok && i < count) {
            tree.nodes[slot].coefficients[0] = (DP_PRIME - points[i]) % DP_PRIME;
            tree.nodes[slot].coefficients[1] = 1;
        } else if (*ok) tree.nodes[slot].coefficients[0] = 1;
    }
    usz node = tree.size;
    while (node > 1 && *ok) {
        node--;
        tree.nodes[node].coefficients = dp_multiply(
            tree.nodes[2 * node].coefficients, tree.nodes[2 * node].length,
            tree.nodes[2 * node + 1].coefficients, tree.nodes[2 * node + 1].length,
            &tree.nodes[node].length, ok);
    }
    if (!*ok) dp_tree_free(tree);
}

fn void dp_visit(DPTree* tree, usz node, long* value, usz length, long* output, bool* ok) {
    if (!*ok || length == 0) return;
    if (node >= tree.size) {
        usz index = node - tree.size;
        if (index < tree.count) output[index] = value[0];
        return;
    }
    usz left_len = 0, right_len = 0;
    long* left = dp_remainder(value, length, tree.nodes[2 * node].coefficients,
                              tree.nodes[2 * node].length, &left_len, ok);
    long* right = dp_remainder(value, length, tree.nodes[2 * node + 1].coefficients,
                               tree.nodes[2 * node + 1].length, &right_len, ok);
    dp_visit(tree, 2 * node, left, left_len, output, ok);
    dp_visit(tree, 2 * node + 1, right, right_len, output, ok);
    free(left); free(right);
}

fn long dp_ordered(long* points, usz count, bool* ok) {
    if (!*ok) return 0;
    if (count <= 32) {
        long product = 1;
        for (usz i = 0; i < count; i++)
            for (usz j = i + 1; j < count; j++)
                product = product * ((points[i] - points[j] + DP_PRIME) % DP_PRIME) % DP_PRIME;
        return product;
    }
    usz middle = count / 2, right_count = count - middle;
    long product = dp_ordered(points, middle, ok);
    product = product * dp_ordered(points + middle, right_count, ok) % DP_PRIME;
    if (!*ok || product == 0) return 0;
    DPTree left, right;
    dp_tree_init(&left, points, middle, ok);
    dp_tree_init(&right, points + middle, right_count, ok);
    long* values = dp_allocate(right_count, ok);
    if (*ok) {
        usz root_len = 0;
        long* root = dp_remainder(left.nodes[1].coefficients, left.nodes[1].length,
                                  right.nodes[1].coefficients, right.nodes[1].length, &root_len, ok);
        dp_visit(&right, 1, root, root_len, values, ok);
        free(root);
    }
    if (*ok) for (usz i = 0; i < right_count; i++) product = product * values[i] % DP_PRIME;
    free(values); dp_tree_free(&left); dp_tree_free(&right);
    if (!*ok) return 0;
    if ((middle & 1) != 0 && (right_count & 1) != 0 && product != 0) product = DP_PRIME - product;
    return product;
}

fn long difference_product(long* input, usz length) @export("difference_product") {
    if (input == null || length == 0 || input[0] < 0 || input[0] > 65536) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;
    for (usz i = 0; i < count; i++) if (input[i + 1] < 0 || input[i + 1] >= DP_PRIME) return -1;
    bool ok = true;
    long result = dp_ordered(input + 1, count, &ok);
    return ok ? result : -1;
}
