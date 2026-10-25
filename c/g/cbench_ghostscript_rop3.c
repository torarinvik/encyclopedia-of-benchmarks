/* Independently written bounded profile of Ghostscript's ROP3 semantics.
 * Upstream source carries Copyright (C) 1995, 1996 Aladdin Enterprises;
 * see benchmarks/g/cbench_ghostscript_rop3/LICENSE.txt for full AFPL v5 terms. */
#include <stddef.h>
#include <stdint.h>

int64_t cbench_ghostscript_rop3(const int64_t *values, size_t length)
{
    if (length > 5 || (length != 0 && values == NULL)) return -1;
    if (length != 4) return -1;
    for (size_t i = 0; i < 3; ++i)
        if (values[i] < 0 || values[i] > INT64_C(4294967295)) return -1;
    if (values[3] < 0 || values[3] > 255) return -1;
    uint64_t d = (uint64_t)values[0], s = (uint64_t)values[1];
    uint64_t t = (uint64_t)values[2], code = (uint64_t)values[3];
    uint64_t result = 0;
    for (unsigned bit = 0; bit < 32; ++bit) {
        unsigned index = (unsigned)(((t >> bit) & 1) << 2) |
                         (unsigned)(((s >> bit) & 1) << 1) |
                         (unsigned)((d >> bit) & 1);
        if ((code >> index) & 1) result |= UINT64_C(1) << bit;
    }
    return (int64_t)result;
}
