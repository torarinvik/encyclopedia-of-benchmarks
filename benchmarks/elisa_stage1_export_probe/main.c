#include <stdint.h>
#include <stddef.h>

extern int64_t dsa_verify(const int64_t *input, size_t length);

int main(void) {
    const int64_t input[] = {20, 22};
    return dsa_verify(input, 2) == 42 ? 0 : 1;
}
