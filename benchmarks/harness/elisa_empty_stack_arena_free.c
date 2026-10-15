/*
 * Elisa emits arena_free for a function's implicit arena even when it remains empty.
 * The maximum_unique_subarray port uses only fixed-size stack arrays; its object has no
 * allocation references. This no-op supplies that empty-arena cleanup at the C ABI.
 */
#include <stdlib.h>

void arena_free(void *arena) {
    if (arena != NULL && *(void **)arena != NULL) {
        abort();
    }
}
