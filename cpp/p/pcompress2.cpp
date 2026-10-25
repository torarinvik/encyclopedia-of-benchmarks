/* Clean-room bounded pcompress2 pipeline. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxLength = 32;
constexpr std::size_t MaxOutputBytes = 8 + MaxLength * 16;
constexpr int Symbols = 257;
constexpr int MaxFrequency = 16383;
struct BitWriter { std::uint8_t *bytes; std::size_t length; std::uint8_t buffer; int bitsToGo; };

bool rotationLess(const std::uint8_t *input, std::size_t n, std::size_t left, std::size_t right) {
    for (std::size_t offset = 0; offset < n; ++offset) {
        const auto a = input[(left + offset) % n], b = input[(right + offset) % n];
        if (a != b) return a < b;
    }
    return left < right;
}
void outputBit(BitWriter &w, int bit) {
    w.buffer >>= 1;
    if (bit) w.buffer |= 0x80;
    if (--w.bitsToGo == 0) { w.bytes[w.length++] = w.buffer; w.bitsToGo = 8; }
}
void bitPlusFollow(BitWriter &w, int bit, int &follow) {
    outputBit(w, bit);
    while (follow > 0) { outputBit(w, !bit); --follow; }
}
void encodeSymbol(int symbol, const int *cum, std::uint32_t &low, std::uint32_t &high,
                  int &follow, BitWriter &w) {
    const std::uint64_t span = std::uint64_t(high - low) + 1;
    const auto oldLow = low;
    high = oldLow + static_cast<std::uint32_t>(span * static_cast<unsigned>(cum[symbol - 1]) / static_cast<unsigned>(cum[0])) - 1;
    low = oldLow + static_cast<std::uint32_t>(span * static_cast<unsigned>(cum[symbol]) / static_cast<unsigned>(cum[0]));
    for (;;) {
        if (high < 32768) bitPlusFollow(w, 0, follow);
        else if (low >= 32768) { bitPlusFollow(w, 1, follow); low -= 32768; high -= 32768; }
        else if (low >= 16384 && high < 49152) { ++follow; low -= 16384; high -= 16384; }
        else break;
        low *= 2; high = high * 2 + 1;
    }
}
void updateModel(int symbol, int *charToIndex, std::uint8_t *indexToChar, int *freq, int *cum) {
    if (cum[0] == MaxFrequency) {
        int total = 0;
        for (int i = Symbols; i >= 0; --i) { freq[i] = (freq[i] + 1) / 2; cum[i] = total; total += freq[i]; }
    }
    int i = symbol;
    while (freq[i] == freq[i - 1]) --i;
    if (i < symbol) {
        const auto a = indexToChar[i], b = indexToChar[symbol];
        indexToChar[i] = b; indexToChar[symbol] = a;
        charToIndex[a] = symbol; charToIndex[b] = i;
    }
    ++freq[i];
    while (i > 0) ++cum[--i];
}
std::size_t arithmeticEncode(const std::uint8_t *data, std::size_t count, std::uint8_t *encoded) {
    int charToIndex[256]{}; std::uint8_t indexToChar[Symbols + 1]{};
    int freq[Symbols + 1]{}, cum[Symbols + 1]{};
    for (int i = 0; i < 256; ++i) { charToIndex[i] = i + 1; indexToChar[i + 1] = static_cast<std::uint8_t>(i); }
    for (int i = 0; i <= Symbols; ++i) { freq[i] = 1; cum[i] = Symbols - i; }
    freq[0] = 0;
    BitWriter w{encoded, 0, 0, 8}; std::uint32_t low = 0, high = 65535; int follow = 0;
    for (std::size_t i = 0; i < count; ++i) { const int symbol = charToIndex[data[i]]; encodeSymbol(symbol, cum, low, high, follow, w); updateModel(symbol, charToIndex, indexToChar, freq, cum); }
    encodeSymbol(257, cum, low, high, follow, w);
    ++follow; bitPlusFollow(w, low < 16384 ? 0 : 1, follow);
    w.bytes[w.length++] = static_cast<std::uint8_t>(w.buffer >> w.bitsToGo);
    return w.length;
}
std::size_t compressBounded(const std::uint8_t *input, std::size_t n, std::uint8_t *output) {
    std::size_t order[MaxLength]; std::uint8_t last[MaxLength], rle[MaxLength * 2]; std::size_t rleLength = 0;
    for (std::size_t i = 0; i < n; ++i) order[i] = i;
    for (std::size_t i = 1; i < n; ++i) { const auto key = order[i]; auto j = i; while (j > 0 && rotationLess(input, n, key, order[j - 1])) { order[j] = order[j - 1]; --j; } order[j] = key; }
    std::size_t primary = 0;
    for (std::size_t row = 0; row < n; ++row) { if (order[row] == 0) primary = row; last[row] = input[(order[row] + n - 1) % n]; }
    for (std::size_t i = 0; i < n;) {
        std::size_t count = 1; const auto value = last[i];
        while (i + count < n && last[i + count] == value && count < 127) ++count;
        if (count == 1) {
            while (i + count < n && last[i + count - 1] != last[i + count] && (i + count + 1 == n || last[i + count] != last[i + count + 1])) ++count;
            rle[rleLength++] = static_cast<std::uint8_t>(count & 0x7f);
            for (std::size_t j = 0; j < count; ++j) rle[rleLength++] = last[i + j];
            i += count;
        } else { rle[rleLength++] = static_cast<std::uint8_t>(count | 0x80); rle[rleLength++] = value; i += count; }
    }
    output[0] = static_cast<std::uint8_t>(n); output[1] = output[2] = output[3] = 0;
    output[4] = static_cast<std::uint8_t>(primary); output[5] = output[6] = output[7] = 0;
    return 8 + arithmeticEncode(rle, rleLength, output + 8);
}
}

extern "C" std::int64_t pcompress2(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t outputCapacity) noexcept {
    if (values == nullptr || length < 2 || values[0] < 1 || values[0] > static_cast<std::int64_t>(MaxLength)) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    if (length != n + 1) return -1;
    std::uint8_t input[MaxLength];
    for (std::size_t i = 0; i < n; ++i) { if (values[i + 1] < 0 || values[i + 1] > 255) return -1; input[i] = static_cast<std::uint8_t>(values[i + 1]); }
    std::uint8_t encoded[MaxOutputBytes];
    const auto encodedLength = compressBounded(input, n, encoded);
    if (output == nullptr || outputCapacity < encodedLength) return -2;
    for (std::size_t i = 0; i < encodedLength; ++i) output[i] = encoded[i];
    return static_cast<std::int64_t>(encodedLength);
}
