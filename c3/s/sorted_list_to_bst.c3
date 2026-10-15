module sorted_list_to_bst;

fn usz emit_tree(long* values, usz start, usz end, char* output, usz position)
{
    if (start == end) { output[position] = 0; return position + 1; }
    usz middle = start;
    usz fast = start;
    while (fast < end && fast + 1 < end) { fast += 2; middle++; }
    output[position++] = 1;
    long encoded = values[middle];
    if (encoded < 0) encoded += 4294967296;
    output[position++] = (char)(encoded & 255);
    output[position++] = (char)((encoded >> 8) & 255);
    output[position++] = (char)((encoded >> 16) & 255);
    output[position++] = (char)(encoded >> 24);
    position = emit_tree(values, start, middle, output, position);
    return emit_tree(values, middle + 1, end, output, position);
}

// Build a height-balanced BST from a sorted linked-list value sequence and serialize it.
fn long sorted_list_to_bst(long* values, usz length, char* output, usz output_capacity) @export("sorted_list_to_bst")
{
    if (length > 64) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647 ||
            (index > 0 && values[index - 1] > values[index])) return -1;
    }
    usz required = 6 * length + 1;
    if (output_capacity < required || output == null) return -2;
    emit_tree(values, 0, length, output, 0);
    return (long)length;
}
