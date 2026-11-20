module cupif_giannini_tree_traversal;

fn long cupif_giannini_tree_traversal(long* input, usz length, char* output, usz capacity) @export("cupif_giannini_tree_traversal") {
    if (input == null || length < 2 || length > 3) return -1;
    if (length != 2) return -1;

    long height_value = input[0];
    long key_value = input[1];
    if (height_value < 0 || height_value > 6) return -1;
    int height = (int)height_value;
    usz leaf_count = (usz)1 << height;
    if (key_value < 0 || (usz)key_value >= leaf_count) return -1;
    if (output == null || capacity < leaf_count) return -2;

    for (usz count = 0; count < leaf_count; count++) {
        ulong path = (ulong)count ^ (ulong)key_value;
        char leaf_code = 0;
        for (int depth = 0; depth < height; depth++) {
            if (((path >> depth) & 1) != 0) leaf_code |= (char)(1 << depth);
        }
        output[count] = leaf_code;
    }
    return (long)leaf_count;
}
