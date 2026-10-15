/* Return the logical complement on the Boolean 0/1 domain. */
#include <stdint.h>

int64_t not_gate(int64_t value)
{
    return value == 0 ? 1 : 0;
}
