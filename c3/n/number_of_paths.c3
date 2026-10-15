module number_of_paths;

fn uint count_from(long* matrix, uint n, uint current, uint destination, uint visited) {
    if (current == destination) return 1;
    visited |= 1 << current;
    uint count = 0;
    for (uint next = 0; next < n; next++) {
        if (matrix[current * n + next] == 1 && (visited & (1 << next)) == 0)
            count += count_from(matrix, n, next, destination, visited);
    }
    return count;
}

fn long number_of_paths(long* values, usz length) @export("number_of_paths") {
    if (values == null || length < 3 || values[0] < 1 || values[0] > 10) return -1;
    uint n = (uint)values[0];
    if (length != 3 + n * n) return -1;
    if (values[1] < 0 || values[1] > 4294967295 || values[2] < 0 || values[2] > 4294967295)
        return -1;
    for (usz i = 3; i < length; i++) if (values[i] != 0 && values[i] != 1) return -1;
    uint source = (uint)values[1];
    uint destination = (uint)values[2];
    if (source >= n || destination >= n) return 0;
    return (long)count_from(values + 3, n, source, destination, 0);
}
