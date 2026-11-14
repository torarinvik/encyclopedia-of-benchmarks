// Uncompiled independently written symmetric-group convolution draft.
#include "symmetric_group_convolution_fft_inverse.hpp"
#include <cstddef>
#include <cstdint>
#include <new>

extern "C" std::int64_t symmetric_group_convolution_fft(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    using namespace symmetric_group_fft;
    if (!input || length < 1 || length > 725762 || input[0] < 1 || input[0] > 9) return -1;
    const int n = static_cast<int>(input[0]);
    const std::size_t count = factorials[n];
    if (length != 1+2*count) return -1;
    for (std::size_t i=1; i<length; ++i)
        if (input[i] < 0 || input[i] >= modulus) return -1;
    if (!output || capacity < 4*count) return -2;
    try {
        const auto levels = make_levels(n);
        const std::vector<std::int64_t> a(input+1,input+1+count);
        const std::vector<std::int64_t> b(input+1+count,input+1+2*count);
        const auto left = forward(levels,n,a);
        const auto right = forward(levels,n,b);
        Blocks product;
        product.reserve(levels[n].size());
        for (std::size_t shape=0; shape<levels[n].size(); ++shape) {
            const auto d = levels[n][shape].basis.size();
            Block block(d*d,0);
            for (std::size_t row=0; row<d; ++row)
                for (std::size_t inner=0; inner<d; ++inner)
                    for (std::size_t col=0; col<d; ++col) {
                        const auto index = row*d+col;
                        block[index] = (block[index]+left[shape][row*d+inner]*right[shape][inner*d+col])%modulus;
                    }
            product.push_back(std::move(block));
        }
        const auto result = inverse(levels,n,product);
        for (std::size_t i=0; i<count; ++i) {
            const auto value = static_cast<std::uint32_t>(result[i]);
            for (int byte=0; byte<4; ++byte)
                output[4*i+static_cast<std::size_t>(byte)] = static_cast<std::uint8_t>(value>>(8*byte));
        }
        return static_cast<std::int64_t>(4*count);
    } catch (const std::bad_alloc&) {
        return -3;
    } catch (const std::logic_error&) {
        // An internal plan or representation invariant failed. Do not let a
        // C++ exception cross the C ABI, and leave the output untouched.
        return -4;
    }
}
