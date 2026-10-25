/* Independent ROP3 truth-table transforms; full AFPL v5 is bundled. */
#include <stddef.h>
#include <stdint.h>

int64_t cbench_ghostscript_rop3_transform(const int64_t *values, size_t length)
{
    if (length > 3 || (length != 0 && values == NULL) || length != 2) return -1;
    if (values[0] < 0 || values[0] > 14 || values[1] < 0 || values[1] > 255) return -1;
    const unsigned mode = (unsigned)values[0];
    const uint64_t code = (uint64_t)values[1];
    uint64_t result = 0;
    for (unsigned index = 0; index < 8; ++index) {
        const unsigned d = index & 1u, s = (index >> 1) & 1u, t = (index >> 2) & 1u;
        unsigned source_index = index;
        int forced = -1;
        if (mode <= 2) source_index ^= 1u << mode;
        else if (mode <= 8) {
            const unsigned dimension = (mode - 3) / 2;
            const unsigned pinned = (mode - 3) & 1u;
            source_index = (index & ~(1u << dimension)) | (pinned << dimension);
        } else if (mode == 9) source_index = (index & ~6u) | (s << 2) | (t << 1);
        else if (mode <= 13) {
            const unsigned operand = mode < 12 ? s : t;
            const unsigned required = (mode - 10) & 1u;
            if (operand == required) forced = (int)d;
        } else forced = 1 - (int)((code >> index) & 1u);
        const unsigned bit = forced < 0 ? (unsigned)((code >> source_index) & 1u) : (unsigned)forced;
        result |= (uint64_t)bit << index;
    }
    return (int64_t)result;
}
