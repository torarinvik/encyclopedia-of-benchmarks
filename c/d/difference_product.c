/* Independent difference-product C draft; see the package README.
 * Registered draft; compilation and output remain unverified. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define DP_PRIME INT64_C(998244353)

typedef struct {
    size_t length;
    int64_t *coefficient;
} dp_poly;

static dp_poly dp_new(size_t length, int *ok) {
    dp_poly result = {length, NULL};
    if (!*ok) { result.length = 0; return result; }
    if (length != 0) {
        result.coefficient = calloc(length, sizeof(*result.coefficient));
        if (result.coefficient == NULL) { result.length = 0; *ok = 0; }
    }
    return result;
}

static void dp_free(dp_poly *poly) {
    free(poly->coefficient);
    poly->coefficient = NULL;
    poly->length = 0;
}

static int64_t dp_power(int64_t value, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * value % DP_PRIME;
        value = value * value % DP_PRIME;
        exponent >>= 1;
    }
    return result;
}

/* Transform lengths are powers of two at most 2^23, the field's root order. */
static void dp_transform(int64_t *values, size_t size, int inverse) {
    size_t reversed = 0;
    for (size_t i = 1; i < size; ++i) {
        size_t bit = size >> 1;
        while (reversed & bit) { reversed ^= bit; bit >>= 1; }
        reversed ^= bit;
        if (i < reversed) {
            const int64_t temporary = values[i];
            values[i] = values[reversed];
            values[reversed] = temporary;
        }
    }
    for (size_t width = 2; width <= size; width <<= 1) {
        int64_t step = dp_power(3, (DP_PRIME - 1) / (int64_t)width);
        if (inverse) step = dp_power(step, DP_PRIME - 2);
        for (size_t start = 0; start < size; start += width) {
            int64_t root = 1;
            for (size_t j = 0; j < width / 2; ++j) {
                const int64_t even = values[start + j];
                const int64_t odd = values[start + j + width / 2] * root % DP_PRIME;
                values[start + j] = (even + odd) % DP_PRIME;
                values[start + j + width / 2] = (even - odd + DP_PRIME) % DP_PRIME;
                root = root * step % DP_PRIME;
            }
        }
    }
    if (inverse) {
        const int64_t scale = dp_power((int64_t)size, DP_PRIME - 2);
        for (size_t i = 0; i < size; ++i) values[i] = values[i] * scale % DP_PRIME;
    }
}

static dp_poly dp_multiply(const dp_poly *a, const dp_poly *b, int *ok) {
    if (!*ok || a->length == 0 || b->length == 0) return dp_new(0, ok);
    const size_t length = a->length + b->length - 1;
    if (a->length <= 32 || b->length <= 32) {
        dp_poly result = dp_new(length, ok);
        if (!*ok) return result;
        for (size_t i = 0; i < a->length; ++i)
            for (size_t j = 0; j < b->length; ++j)
                result.coefficient[i + j] = (result.coefficient[i + j] +
                    a->coefficient[i] * b->coefficient[j]) % DP_PRIME;
        return result;
    }
    size_t size = 1;
    while (size < length) size <<= 1;
    dp_poly left = dp_new(size, ok);
    dp_poly right = dp_new(size, ok);
    if (!*ok) { dp_free(&left); dp_free(&right); return dp_new(0, ok); }
    for (size_t i = 0; i < a->length; ++i) left.coefficient[i] = a->coefficient[i];
    for (size_t i = 0; i < b->length; ++i) right.coefficient[i] = b->coefficient[i];
    dp_transform(left.coefficient, size, 0);
    dp_transform(right.coefficient, size, 0);
    for (size_t i = 0; i < size; ++i)
        left.coefficient[i] = left.coefficient[i] * right.coefficient[i] % DP_PRIME;
    dp_transform(left.coefficient, size, 1);
    dp_free(&right);
    left.length = length;
    return left;
}

static dp_poly dp_copy_prefix(const dp_poly *source, size_t length, int *ok) {
    if (length > source->length) length = source->length;
    dp_poly copy = dp_new(length, ok);
    if (*ok) for (size_t i = 0; i < length; ++i) copy.coefficient[i] = source->coefficient[i];
    return copy;
}

/* Newton iteration doubles the number of correct inverse coefficients. */
static dp_poly dp_inverse(const dp_poly *input, size_t count, int *ok) {
    dp_poly result = dp_new(1, ok);
    if (!*ok) return result;
    result.coefficient[0] = dp_power(input->coefficient[0], DP_PRIME - 2);
    while (*ok && result.length < count) {
        size_t next = 2 * result.length;
        if (next > count) next = count;
        dp_poly prefix = dp_copy_prefix(input, next, ok);
        dp_poly product = dp_multiply(&prefix, &result, ok);
        dp_free(&prefix);
        dp_poly correction = dp_new(next, ok);
        if (*ok) {
            for (size_t i = 0; i < next; ++i) {
                int64_t value = i < product.length ? product.coefficient[i] : 0;
                correction.coefficient[i] = (DP_PRIME - value) % DP_PRIME;
            }
            correction.coefficient[0] = (correction.coefficient[0] + 2) % DP_PRIME;
        }
        dp_free(&product);
        dp_poly updated = dp_multiply(&result, &correction, ok);
        dp_free(&correction);
        dp_free(&result);
        if (!*ok) { dp_free(&updated); return dp_new(0, ok); }
        updated.length = next;
        result = updated;
    }
    return result;
}

/* Divide by a monic polynomial using a reversed-series quotient. */
static dp_poly dp_remainder(const dp_poly *dividend, const dp_poly *divisor, int *ok) {
    if (!*ok) return dp_new(0, ok);
    if (dividend->length < divisor->length)
        return dp_copy_prefix(dividend, dividend->length, ok);
    if (divisor->length == 1) return dp_new(0, ok);
    const size_t quotient_length = dividend->length - divisor->length + 1;
    dp_poly high = dp_new(quotient_length, ok);
    dp_poly reversed = dp_new(divisor->length, ok);
    if (*ok) {
        for (size_t i = 0; i < quotient_length; ++i)
            high.coefficient[i] = dividend->coefficient[dividend->length - 1 - i];
        for (size_t i = 0; i < divisor->length; ++i)
            reversed.coefficient[i] = divisor->coefficient[divisor->length - 1 - i];
    }
    dp_poly inverse = *ok ? dp_inverse(&reversed, quotient_length, ok) : dp_new(0, ok);
    dp_free(&reversed);
    dp_poly high_quotient = dp_multiply(&high, &inverse, ok);
    dp_free(&high);
    dp_free(&inverse);
    dp_poly quotient = dp_new(quotient_length, ok);
    if (*ok) for (size_t i = 0; i < quotient_length; ++i)
        quotient.coefficient[i] = high_quotient.coefficient[quotient_length - 1 - i];
    dp_free(&high_quotient);
    dp_poly removed = dp_multiply(&quotient, divisor, ok);
    dp_free(&quotient);
    dp_poly result = dp_new(divisor->length - 1, ok);
    if (*ok) {
        for (size_t i = 0; i < result.length; ++i) {
            const int64_t part = i < removed.length ? removed.coefficient[i] : 0;
            result.coefficient[i] = (dividend->coefficient[i] - part + DP_PRIME) % DP_PRIME;
        }
        while (result.length > 0 && result.coefficient[result.length - 1] == 0) --result.length;
    }
    dp_free(&removed);
    if (!*ok) { dp_free(&result); return dp_new(0, ok); }
    return result;
}

typedef struct {
    size_t size;
    size_t count;
    dp_poly *nodes;
} dp_tree;

static void dp_tree_free(dp_tree *tree) {
    if (tree->nodes != NULL) {
        for (size_t i = 0; i < 2 * tree->size; ++i) dp_free(&tree->nodes[i]);
        free(tree->nodes);
    }
    tree->nodes = NULL;
}

/* Identity padding leaves keep the product tree balanced for any count. */
static dp_tree dp_tree_build(const int64_t *points, size_t count, int *ok) {
    dp_tree tree = {1, count, NULL};
    while (tree.size < count) tree.size <<= 1;
    if (!*ok) return tree;
    tree.nodes = calloc(2 * tree.size, sizeof(*tree.nodes));
    if (tree.nodes == NULL) { *ok = 0; return tree; }
    for (size_t i = 0; i < tree.size && *ok; ++i) {
        dp_poly *leaf = &tree.nodes[tree.size + i];
        *leaf = dp_new(i < count ? 2 : 1, ok);
        if (*ok && i < count) {
            leaf->coefficient[0] = (DP_PRIME - points[i]) % DP_PRIME;
            leaf->coefficient[1] = 1;
        } else if (*ok) leaf->coefficient[0] = 1;
    }
    for (size_t i = tree.size; i-- > 1 && *ok;)
        tree.nodes[i] = dp_multiply(&tree.nodes[2 * i], &tree.nodes[2 * i + 1], ok);
    if (!*ok) dp_tree_free(&tree);
    return tree;
}

/* A zero remainder evaluates to zero throughout its entire subtree. */
static void dp_tree_evaluate(const dp_tree *tree, size_t node, const dp_poly *value,
                             int64_t *output, int *ok) {
    if (!*ok || value->length == 0) return;
    if (node >= tree->size) {
        const size_t index = node - tree->size;
        if (index < tree->count) output[index] = value->coefficient[0];
        return;
    }
    dp_poly left = dp_remainder(value, &tree->nodes[2 * node], ok);
    dp_poly right = dp_remainder(value, &tree->nodes[2 * node + 1], ok);
    dp_tree_evaluate(tree, 2 * node, &left, output, ok);
    dp_tree_evaluate(tree, 2 * node + 1, &right, output, ok);
    dp_free(&left);
    dp_free(&right);
}

static int64_t dp_ordered(const int64_t *points, size_t count, int *ok) {
    if (!*ok) return 0;
    if (count <= 32) {
        int64_t result = 1;
        for (size_t i = 0; i < count; ++i)
            for (size_t j = i + 1; j < count; ++j)
                result = result * ((points[i] - points[j] + DP_PRIME) % DP_PRIME) % DP_PRIME;
        return result;
    }
    const size_t middle = count / 2;
    const size_t right_count = count - middle;
    int64_t result = dp_ordered(points, middle, ok);
    result = result * dp_ordered(points + middle, right_count, ok) % DP_PRIME;
    if (!*ok || result == 0) return 0;
    dp_tree left = dp_tree_build(points, middle, ok);
    dp_tree right = dp_tree_build(points + middle, right_count, ok);
    int64_t *evaluations = NULL;
    if (*ok) {
        evaluations = calloc(right_count, sizeof(*evaluations));
        if (evaluations == NULL) *ok = 0;
    }
    if (*ok) {
        dp_poly root = dp_remainder(&left.nodes[1], &right.nodes[1], ok);
        dp_tree_evaluate(&right, 1, &root, evaluations, ok);
        dp_free(&root);
    }
    if (*ok) for (size_t i = 0; i < right_count; ++i)
        result = result * evaluations[i] % DP_PRIME;
    free(evaluations);
    dp_tree_free(&left);
    dp_tree_free(&right);
    if (!*ok) return 0;
    if ((middle & 1) && (right_count & 1) && result != 0) result = DP_PRIME - result;
    return result;
}

int64_t difference_product(const int64_t *input, size_t length) {
    if (!input || length == 0 || input[0] < 0 || input[0] > 65536) return -1;
    const size_t count = (size_t)input[0];
    if (length != count + 1) return -1;
    for (size_t i = 0; i < count; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= DP_PRIME) return -1;
    int ok = 1;
    const int64_t result = dp_ordered(input + 1, count, &ok);
    return ok ? result : -1;
}
