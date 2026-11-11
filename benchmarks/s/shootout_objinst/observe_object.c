/* Compile separately so each port's initialized object escapes before it is freed. */
void benchmark_observe_object(const void *object)
{
    const void *volatile observed = object;
    (void)observed;
}
