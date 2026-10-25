/* Independent bounded profile of the source-defined ROP3 predicate.
 * Copyright (C) 1995, 1996 Aladdin Enterprises in upstream source;
 * full Aladdin Free Public License v5 is bundled with the package. */
#include <stddef.h>
#include <stdint.h>

int64_t cbench_ghostscript_rop3_idempotence(const int64_t *values, size_t length)
{
    if (length > 2 || (length != 0 && values == NULL) || length != 1) return -1;
    if (values[0] < 0 || values[0] > 255) return -1;
    uint64_t code = (uint64_t)values[0];
    for (unsigned bit = 1; bit < 8; bit += 2)
        if (((code >> bit) & 1) != 0 && ((code >> (bit - 1)) & 1) == 0) return 0;
    return 1;
}
