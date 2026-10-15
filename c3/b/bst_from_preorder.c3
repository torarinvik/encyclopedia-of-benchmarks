module bst_from_preorder;

fn bool valid_preorder(long* values, usz start, usz end, long lower, long upper)
{
    if (start == end) return true;
    long root = values[start];
    if (root <= lower || root >= upper) return false;
    usz split = start + 1;
    while (split < end && values[split] < root) split++;
    return valid_preorder(values, start + 1, split, lower, root) &&
           valid_preorder(values, split, end, root, upper);
}

fn usz emit_preorder_tree(long* values, usz start, usz end, char* output, usz position)
{
    if (start == end) {
        output[position] = 0;
        return position + 1;
    }
    long root = values[start];
    usz split = start + 1;
    while (split < end && values[split] < root) split++;
    output[position++] = 1;
    long encoded = root;
    if (encoded < 0) encoded += 4294967296;
    output[position++] = (char)(encoded & 255);
    output[position++] = (char)((encoded >> 8) & 255);
    output[position++] = (char)((encoded >> 16) & 255);
    output[position++] = (char)(encoded >> 24);
    position = emit_preorder_tree(values, start + 1, split, output, position);
    return emit_preorder_tree(values, split, end, output, position);
}

// Validate and serialize a strict BST reconstructed from preorder values.
fn long bst_from_preorder(long* values, usz length, char* output, usz output_capacity) @export("bst_from_preorder")
{
    if (length == 0 || length > 15) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -1;
    }
    if (!valid_preorder(values, 0, length, -2147483649, 2147483648)) return -1;
    usz required = 6 * length + 1;
    if (output_capacity < required || output == null) return -2;
    emit_preorder_tree(values, 0, length, output, 0);
    return (long)length;
}
