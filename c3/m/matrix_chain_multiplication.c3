module matrix_chain_multiplication;

const usz MAX_DIMS = 65;
const long MAX_DIMENSION = 1000;
const usz MAX_CELLS = 4225;

fn long matrix_chain_multiplication(long* dimensions, usz length) @export("matrix_chain_multiplication")
{
    if (length > MAX_DIMS) return -1;
    for (usz index = 0; index < length; index++) {
        if (dimensions[index] < 1 || dimensions[index] > MAX_DIMENSION) return -1;
    }
    if (length < 2) return 0;

    usz matrix_count = length - 1;
    long[MAX_CELLS] costs;
    for (usz index = 0; index < MAX_CELLS; index++) costs[index] = 0;
    for (usz chain_length = 2; chain_length <= matrix_count; chain_length++) {
        for (usz start = 0; start + chain_length <= matrix_count; start++) {
            usz end = start + chain_length - 1;
            long best = 9223372036854775807;
            for (usz split = start; split < end; split++) {
                long cost = costs[start * MAX_DIMS + split]
                    + costs[(split + 1) * MAX_DIMS + end]
                    + dimensions[start] * dimensions[split + 1] * dimensions[end + 1];
                if (cost < best) best = cost;
            }
            costs[start * MAX_DIMS + end] = best;
        }
    }
    return costs[matrix_count - 1];
}
