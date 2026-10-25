/*
Copyright (C) 1996 McGill University.
Copyright (C) 1996 McCAT System Group.
Copyright (C) 1996 ACAPS Benchmark Administrator
                   benadmin@acaps.cs.mcgill.ca

This program is free software; you can redistribute it and/or modify
it provided this copyright notice is maintained.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

module mccat_bintr;

const usz MAX_NODES = 64;
const usz QUERY_COUNT = 100;
const usz OUTPUT_BYTES = 33;

fn int tree_size(int* values, int* left, int* right, int node) {
    if (node < 0) return 0;
    return 1 + tree_size(values, left, right, left[node]) + tree_size(values, left, right, right[node]);
}

fn double tree_sum(int* values, int* left, int* right, int node) {
    if (node < 0) return 0.0;
    return (double)values[node] + tree_sum(values, left, right, left[node]) + tree_sum(values, left, right, right[node]);
}

fn bool member_dfs(int* values, int* left, int* right, int node, int sought) {
    if (node < 0) return false;
    if (values[node] == sought) return true;
    if (member_dfs(values, left, right, left[node], sought)) return true;
    return member_dfs(values, left, right, right[node], sought);
}

fn void put_u32(char* output, usz offset, uint value) {
    for (usz i = 0; i < 4; i++) output[offset + i] = (char)(value >> (8 * i));
}

fn void put_f64(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz i = 0; i < 8; i++) { output[offset + i] = (char)(bits & 255); bits >>= 8; }
}

fn long mccat_bintr(long* input, usz length, char* output, usz capacity) @export("mccat_bintr") {
    if (input == null || length < 103 || length > MAX_NODES + 102) return -1;
    long node_count_value = input[0];
    if (node_count_value < 1 || node_count_value > 64) return -1;
    usz node_count = (usz)node_count_value;
    if (length != node_count + 102 || input[node_count + 1] != 100) return -1;
    for (usz i = 0; i < node_count; i++)
        if (input[i + 1] == 0 || input[i + 1] < -32768 || input[i + 1] > 32767) return -1;
    for (usz i = 0; i < QUERY_COUNT; i++)
        if (input[node_count + 2 + i] == 0 || input[node_count + 2 + i] < -32768 || input[node_count + 2 + i] > 32767) return -1;
    if (output == null || capacity < OUTPUT_BYTES) return -2;

    int[64] values;
    int[64] left;
    int[64] right;
    int root = -1;
    int used = 0;
    for (usz i = 0; i < node_count; i++) {
        int value = (int)input[i + 1];
        if (root < 0) {
            root = 0; values[0] = value; left[0] = -1; right[0] = -1; used = 1;
            continue;
        }
        int current = root;
        while (true) {
            if (value == values[current]) break;
            if (value < values[current]) {
                if (left[current] < 0) { left[current] = used; values[used] = value; left[used] = -1; right[used] = -1; used++; break; }
                current = left[current];
            } else {
                if (right[current] < 0) { right[current] = used; values[used] = value; left[used] = -1; right[used] = -1; used++; break; }
                current = right[current];
            }
        }
    }
    int size = tree_size(&values[0], &left[0], &right[0], root);
    double sum = tree_sum(&values[0], &left[0], &right[0], root);
    double mean = sum / (double)size;
    for (usz i = 0; i < OUTPUT_BYTES; i++) output[i] = 0;
    put_u32(output, 0, (uint)size);
    put_f64(output, 4, sum);
    put_f64(output, 12, mean);
    for (usz i = 0; i < QUERY_COUNT; i++)
        if (member_dfs(&values[0], &left[0], &right[0], root, (int)input[node_count + 2 + i]))
            output[20 + i / 8] |= (char)(1 << (i & 7));
    return (long)OUTPUT_BYTES;
}
