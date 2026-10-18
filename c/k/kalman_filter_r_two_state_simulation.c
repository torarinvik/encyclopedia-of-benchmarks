#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_OBSERVATIONS 1
#define MAX_OBSERVATIONS 12
#define MAX_OUTPUT_ELEMENTS 30
#define MIN_OBSERVATION -1000.0
#define MAX_OBSERVATION 1000.0

int64_t kalman_filter_r_two_state_simulation(
    const double *input, size_t input_length, double *output, size_t output_capacity)
{
    if (input == NULL || input_length < MIN_OBSERVATIONS || input_length > MAX_OBSERVATIONS)
        return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!isfinite(input[i]) || input[i] < MIN_OBSERVATION || input[i] > MAX_OBSERVATION)
            return -1;
    }

    const size_t result_length = 2 * input_length + 6;
    if (result_length > MAX_OUTPUT_ELEMENTS) return -1;
    if (output == NULL || output_capacity < result_length) return -2;

    /* R matrix(c(1,1,0,1), nrow=2) fills columns first: A = [[1,0],[1,1]]. */
    double state[2] = {input[0], 0.0};
    double covariance[2][2] = {{1.0, 0.0}, {0.0, 1.0}};
    double trace[2 * MAX_OBSERVATIONS];
    double final_state_pred[2] = {0.0, 0.0};
    double final_covariance_pred[2][2] = {{0.0, 0.0}, {0.0, 0.0}};

    for (size_t step = 0; step < input_length; ++step) {
        final_state_pred[0] = state[0];
        final_state_pred[1] = state[0] + state[1];

        /* Compute A*P, then (A*P)*A^T, then add Q = 0.0001 I. */
        const double temp[2][2] = {
            {covariance[0][0], covariance[0][1]},
            {covariance[0][0] + covariance[1][0],
             covariance[0][1] + covariance[1][1]},
        };
        final_covariance_pred[0][0] = temp[0][0] + 0.0001;
        final_covariance_pred[0][1] = temp[0][0] + temp[0][1];
        final_covariance_pred[1][0] = temp[1][0];
        final_covariance_pred[1][1] = temp[1][0] + temp[1][1] + 0.0001;

        const double innovation = final_covariance_pred[0][0] + 0.1;
        const double gain[2] = {
            final_covariance_pred[0][0] / innovation,
            final_covariance_pred[1][0] / innovation,
        };
        const double residual = input[step] - final_state_pred[0];
        state[0] = final_state_pred[0] + gain[0] * residual;
        state[1] = final_state_pred[1] + gain[1] * residual;
        trace[2 * step] = state[0];
        trace[2 * step + 1] = state[1];

        /* The pinned source uses matrix(1,2,2), an all-ones matrix, here. */
        covariance[0][0] = (1.0 - gain[0]) * final_covariance_pred[0][0] +
                           final_covariance_pred[1][0];
        covariance[0][1] = (1.0 - gain[0]) * final_covariance_pred[0][1] +
                           final_covariance_pred[1][1];
        covariance[1][0] = (1.0 - gain[1]) * final_covariance_pred[0][0] +
                           final_covariance_pred[1][0];
        covariance[1][1] = (1.0 - gain[1]) * final_covariance_pred[0][1] +
                           final_covariance_pred[1][1];
    }

    size_t output_index = 0;
    for (size_t i = 0; i < 2 * input_length; ++i) output[output_index++] = trace[i];
    output[output_index++] = final_state_pred[0];
    output[output_index++] = final_state_pred[1];
    output[output_index++] = final_covariance_pred[0][0];
    output[output_index++] = final_covariance_pred[1][0];
    output[output_index++] = final_covariance_pred[0][1];
    output[output_index++] = final_covariance_pred[1][1];
    return (int64_t)output_index;
}
