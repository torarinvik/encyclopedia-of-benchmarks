/* Retrieve one row-major flattened index from a rectangular matrix. */
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t index_2d_array_in_1d(const std::int64_t *input, std::size_t length) noexcept {
    if (!input || length<4) return -1;
    const auto rows=input[0], cols=input[1], index=input[2];
    if (rows<1 || rows>32 || cols<1 || cols>32) return -1;
    const auto cells=static_cast<std::size_t>(rows*cols);
    if (length!=cells+3 || index<0 || static_cast<std::uint64_t>(index)>=cells) return -1;
    for (std::size_t i=0;i<cells;++i) if (input[3+i]<0 || input[3+i]>1000000) return -1;
    const auto row=static_cast<std::size_t>(index)/static_cast<std::size_t>(cols);
    const auto col=static_cast<std::size_t>(index)%static_cast<std::size_t>(cols);
    return input[3+row*static_cast<std::size_t>(cols)+col];
}
