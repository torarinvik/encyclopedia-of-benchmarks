/* Compile separately so each port's initialized object escapes before it is freed. */
#include <stddef.h>
#include <stdlib.h>

void benchmark_observe_object(const void *object)
{
    const void *volatile observed = object;
    (void)observed;
}

void *benchmark_allocate_toggle(size_t size)
{
    return malloc(size);
}

void benchmark_release_toggle(void *object)
{
    free(object);
}

void benchmark_observe_toggle(const void *object)
{
    benchmark_observe_object(object);
}

void *benchmark_allocate_nth_toggle(size_t size)
{
    return malloc(size);
}

void benchmark_release_nth_toggle(void *object)
{
    free(object);
}

void benchmark_observe_nth_toggle(const void *object)
{
    benchmark_observe_object(object);
}
