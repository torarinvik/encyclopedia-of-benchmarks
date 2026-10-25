/* Independent ROP3 truth-table dependency profile; full AFPL v5 is bundled. */
#include <stddef.h>
#include <stdint.h>

int64_t cbench_ghostscript_rop3_operand_usage(const int64_t *values, size_t length)
{
    if (length > 2 || (length != 0 && values == NULL) || length != 1) return -1;
    if (values[0] < 0 || values[0] > 255) return -1;
    const uint64_t code = (uint64_t)values[0];
    unsigned usage = 0;
    for (unsigned dimension = 0; dimension < 3; ++dimension) {
        const unsigned toggle = 1u << dimension;
        for (unsigned index = 0; index < 8; ++index) {
            if ((index & toggle) == 0 && ((code >> index) & 1) != ((code >> (index | toggle)) & 1)) {
                usage |= toggle;
                break;
            }
        }
    }
    return (int64_t)usage;
}
