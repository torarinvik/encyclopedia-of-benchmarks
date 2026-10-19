/* Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
 * Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
 * Original Author: Shay Gal-on. Derived algorithm port; no source blocks copied.
 */
#include <stddef.h>
#include <stdint.h>

static uint16_t crcu8(uint8_t data, uint16_t crc) {
    for (unsigned i = 0; i < 8; ++i) {
        uint8_t feedback = (uint8_t)((data & 1u) ^ (crc & 1u));
        data >>= 1;
        uint8_t carry = 0;
        if (feedback) { crc ^= 0x4002u; carry = 1; }
        crc >>= 1;
        if (carry) crc |= 0x8000u; else crc &= 0x7fffu;
    }
    return crc;
}
static uint16_t crcu16(uint16_t value, uint16_t crc) {
    crc = crcu8((uint8_t)value, crc);
    return crcu8((uint8_t)(value >> 8), crc);
}
static uint16_t crc16(int16_t value, uint16_t crc) { return crcu16((uint16_t)value, crc); }
static uint16_t crcu32(uint32_t value, uint16_t crc) {
    crc = crc16((int16_t)value, crc);
    return crc16((int16_t)(value >> 16), crc);
}

int64_t coremark_crc(const int64_t *values, size_t length) {
    if (!values || length < 4 || length > 49) return -1;
    int64_t count = values[0];
    if (count < 1 || count > 16 || length != 1u + 3u * (size_t)count) return -1;
    int64_t total = 0;
    for (size_t i = 0; i < (size_t)count; ++i) {
        int64_t tag = values[1 + 3*i], seed = values[2 + 3*i], value = values[3 + 3*i];
        if (seed < 0 || seed > 65535) return -1;
        uint16_t crc;
        if (tag == 0 && value >= 0 && value <= 255) crc = crcu8((uint8_t)value, (uint16_t)seed);
        else if (tag == 1 && value >= 0 && value <= 65535) crc = crcu16((uint16_t)value, (uint16_t)seed);
        else if (tag == 2 && value >= 0 && value <= 4294967295LL) crc = crcu32((uint32_t)value, (uint16_t)seed);
        else if (tag == 3 && value >= -32768 && value <= 32767) crc = crc16((int16_t)value, (uint16_t)seed);
        else return -1;
        total += (int64_t)(i + 1) * crc;
    }
    return total;
}
