/* Uncompiled C draft of subgroup Fourier convolution on S_n. */
#include "symmetric_group_convolution_fft_inverse.h"

int64_t symmetric_group_convolution_fft(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 725762 || input[0] < 1 || input[0] > 9) return -1;
    size_t n = (size_t)input[0], count = sg_factorial[n];
    if (length != 1+2*count) return -1;
    for (size_t i = 1; i < length; ++i)
        if (input[i] < 0 || input[i] >= SG_MOD) return -1;
    if (!output || capacity < 4*count) return -2;

    sg_plan plan;
    int status = sg_make_plan(&plan,n);
    if (status) return status;
    sg_blocks left = {0}, right = {0}, product = {0};
    int64_t *result = NULL;
    status = sg_forward(&plan,n,input+1,&left);
    if (status) goto done;
    status = sg_forward(&plan,n,input+1+count,&right);
    if (status) goto done;
    status = sg_allocate_blocks(&plan.levels[n],&product);
    if (status) goto done;
    for (size_t shape = 0; shape < plan.levels[n].count; ++shape) {
        size_t d = plan.levels[n].items[shape].count;
        for (size_t row = 0; row < d; ++row)
            for (size_t inner = 0; inner < d; ++inner)
                for (size_t col = 0; col < d; ++col) {
                    size_t index = row*d+col;
                    product.items[shape][index] = (product.items[shape][index]
                        + left.items[shape][row*d+inner]*right.items[shape][inner*d+col])%SG_MOD;
                }
    }
    status = sg_inverse(&plan,n,&product,&result);
    if (status) goto done;
    for (size_t i = 0; i < count; ++i) {
        uint32_t value = (uint32_t)result[i];
        for (size_t byte = 0; byte < 4; ++byte)
            output[4*i+byte] = (uint8_t)(value >> (8*byte));
    }
done:
    free(result);
    sg_free_blocks(&product); sg_free_blocks(&right); sg_free_blocks(&left);
    sg_free_plan(&plan);
    return status ? status : (int64_t)(4*count);
}
