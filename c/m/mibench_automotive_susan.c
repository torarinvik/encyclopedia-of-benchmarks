/**********************************************************************\
  SUSAN Version 2l by Stephen Smith
  Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
  Department of Clinical Neurology, Oxford University, Oxford, UK
  (Previously in Computer Vision and Image Processing Group - now
  Computer Vision and Electro Optics Group - DERA Chertsey, UK)
  Email:    steve@fmrib.ox.ac.uk
  WWW:      http://www.fmrib.ox.ac.uk/~steve
  (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
  Farnborough, Hampshire, GU14 6TD, UK
  DERA WWW site:
  http://www.dera.gov.uk/
  DERA Computer Vision and Electro Optics Group WWW site:
  http://www.dera.gov.uk/imageprocessing/dera/group_home.html
  DERA Computer Vision and Electro Optics Group point of contact:
  Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
  A UK patent has been granted: "Method for digitally processing
  images to determine the position of edges and/or corners therein for
  guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
  Secretary of State for Defence, UK. 15 January 1997

  This code is issued for research purposes only and remains the
  property of the UK Secretary of State for Defence. This code must
  not be passed on without this header information being kept
  intact. This code must not be sold.
\**********************************************************************/
#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MIN_SIDE = 15, MAX_SIDE = 16, MAX_VALID_INPUT_LENGTH = 257,
       MAX_PARSEABLE_INPUT_LENGTH = 258, MAX_OUTPUT_BYTES = 256,
       MASK_RADIUS = 7 };

static int reflect_index(int index, int side)
{
    if (index < 0) return -index - 1;
    if (index >= side) return 2 * side - index - 1;
    return index;
}

static void setup_weights(int brightness[511], int distance[225])
{
    for (int difference = -255; difference <= 255; ++difference) {
        float temp = (float)difference / 20.0f;
        temp = temp * temp;
        temp = (float)(100.0 * exp(-(double)temp));
        brightness[difference + 255] = (int)temp;
    }
    int index = 0;
    for (int dy = -MASK_RADIUS; dy <= MASK_RADIUS; ++dy) {
        for (int dx = -MASK_RADIUS; dx <= MASK_RADIUS; ++dx) {
            float temp = -16.0f;
            int squared_distance = dx * dx + dy * dy;
            int weight = (int)(100.0 * exp((double)((float)squared_distance / temp)));
            distance[index++] = weight;
        }
    }
}

static uint8_t median_eight(const uint8_t *image, int side, int y, int x)
{
    int values[8];
    int count = 0;
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            if (dx == 0 && dy == 0) continue;
            int sy = reflect_index(y + dy, side);
            int sx = reflect_index(x + dx, side);
            values[count++] = image[sy * side + sx];
        }
    }
    for (int pass = 0; pass < 7; ++pass)
        for (int index = 0; index < 7 - pass; ++index)
            if (values[index] > values[index + 1]) {
                int temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
            }
    return (uint8_t)((values[3] + values[4]) / 2);
}

int64_t mibench_automotive_susan(const int64_t *input, size_t input_length,
                                 uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2u || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < MIN_SIDE || input[0] > MAX_SIDE) return -1;
    int side = (int)input[0];
    size_t pixel_count = (size_t)side * (size_t)side;
    if (input_length != pixel_count + 1u) return -1;
    uint8_t image[MAX_SIDE * MAX_SIDE];
    for (size_t index = 0; index < pixel_count; ++index) {
        int64_t pixel = input[index + 1u];
        if (pixel < 0 || pixel > 255) return -1;
        image[index] = (uint8_t)pixel;
    }
    size_t output_bytes = pixel_count;
    if (output == NULL || output_capacity < output_bytes) return -2;

    int brightness[511];
    int distance[225];
    setup_weights(brightness, distance);
    for (int y = 0; y < side; ++y) {
        for (int x = 0; x < side; ++x) {
            int center = image[y * side + x];
            int area = 0;
            int total = 0;
            int mask_index = 0;
            for (int dy = -MASK_RADIUS; dy <= MASK_RADIUS; ++dy) {
                int sy = reflect_index(y + dy, side);
                for (int dx = -MASK_RADIUS; dx <= MASK_RADIUS; ++dx) {
                    int sx = reflect_index(x + dx, side);
                    int pixel = image[sy * side + sx];
                    int contribution = distance[mask_index++] * brightness[center - pixel + 255];
                    area += contribution;
                    total += contribution * pixel;
                }
            }
            int denominator = area - 10000;
            output[y * side + x] = denominator == 0
                ? median_eight(image, side, y, x)
                : (uint8_t)((total - center * 10000) / denominator);
        }
    }
    return (int64_t)output_bytes;
}
