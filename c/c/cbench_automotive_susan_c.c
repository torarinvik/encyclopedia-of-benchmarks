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
#include <stdlib.h>

enum { MIN_SIDE = 11, MAX_SIDE = 16, MAX_INPUT_LENGTH = 258,
       MAX_OUTPUT_BYTES = 256, MAX_NO_CORNERS = 1850,
       BRIGHTNESS_THRESHOLD = 20, MASK_COUNT = 36 };

static const int8_t MASK_X[MASK_COUNT] = {
    -1, 0, 1,
    -2, -1, 0, 1, 2,
    -3, -2, -1, 0, 1, 2, 3,
    -3, -2, -1, 1, 2, 3,
    -3, -2, -1, 0, 1, 2, 3,
    -2, -1, 0, 1, 2,
    -1, 0, 1
};
static const int8_t MASK_Y[MASK_COUNT] = {
    -3, -3, -3,
    -2, -2, -2, -2, -2,
    -1, -1, -1, -1, -1, -1, -1,
     0,  0,  0,  0,  0,  0,
     1,  1,  1,  1,  1,  1,  1,
     2,  2,  2,  2,  2,
     3,  3,  3
};

static void brightness_table(uint8_t table[513])
{
    for (int difference = -256; difference <= 256; ++difference) {
        double scaled = fabs((double)difference) / BRIGHTNESS_THRESHOLD;
        double term = scaled * scaled;
        term = term * term * term;
        table[difference + 256] = (uint8_t)(100.0 * exp(-term));
    }
}

static int ftoi(float value)
{
    return (int)(value < 0.0f ? (double)value - 0.5 : (double)value + 0.5);
}

static int is_local_corner(const int response[MAX_SIDE * MAX_SIDE], int side,
                           int y, int x)
{
    int value = response[y * side + x];
    for (int dy = -3; dy <= 3; ++dy) {
        for (int dx = -3; dx <= 3; ++dx) {
            if (dx == 0 && dy == 0) continue;
            int neighbor = response[(y + dy) * side + x + dx];
            if (dy < 0 || (dy == 0 && dx < 0)) {
                if (value <= neighbor) return 0;
            } else if (value < neighbor) {
                return 0;
            }
        }
    }
    return 1;
}

static void susan_corners(uint8_t image[MAX_SIDE * MAX_SIDE], int side,
                          const uint8_t brightness[513])
{
    int response[MAX_SIDE * MAX_SIDE] = {0};
    int gradient_x[MAX_SIDE * MAX_SIDE] = {0};
    int gradient_y[MAX_SIDE * MAX_SIDE] = {0};
    int points_x[MAX_SIDE * MAX_SIDE];
    int points_y[MAX_SIDE * MAX_SIDE];
    int point_count = 0;

    for (int y = 5; y < side - 5; ++y) {
        for (int x = 5; x < side - 5; ++x) {
            int center = image[y * side + x];
            int area = 100;
            for (int k = 0; k < MASK_COUNT; ++k) {
                int pixel = image[(y + MASK_Y[k]) * side + x + MASK_X[k]];
                area += brightness[center - pixel + 256];
            }
            if (area >= MAX_NO_CORNERS) continue;

            int gx = 0;
            int gy = 0;
            for (int k = 0; k < MASK_COUNT; ++k) {
                int pixel = image[(y + MASK_Y[k]) * side + x + MASK_X[k]];
                int weight = brightness[center - pixel + 256];
                gx += MASK_X[k] * weight;
                gy += MASK_Y[k] * weight;
            }

            int xx = gx * gx;
            int yy = gy * gy;
            if (xx + yy <= (area * area) / 2) continue;

            int along = 0;
            if (yy < xx) {
                float divide = (float)gy / (float)abs(gx);
                int step_x = abs(gx) / gx;
                for (int distance = 1; distance <= 3; ++distance) {
                    int row = y + ftoi((float)distance * divide);
                    int col = x + distance * step_x;
                    along += brightness[center - image[row * side + col] + 256];
                }
            } else {
                float divide = (float)gx / (float)abs(gy);
                int step_y = abs(gy) / gy;
                for (int distance = 1; distance <= 3; ++distance) {
                    int row = y + distance * step_y;
                    int col = x + ftoi((float)distance * divide);
                    along += brightness[center - image[row * side + col] + 256];
                }
            }
            if (along > 290) {
                int at = y * side + x;
                response[at] = MAX_NO_CORNERS - area;
                gradient_x[at] = (51 * gx) / area;
                gradient_y[at] = (51 * gy) / area;
            }
        }
    }

    for (int y = 5; y < side - 5; ++y) {
        for (int x = 5; x < side - 5; ++x) {
            int at = y * side + x;
            if (response[at] > 0 && is_local_corner(response, side, y, x)) {
                points_x[point_count] = x;
                points_y[point_count] = y;
                ++point_count;
            }
        }
    }

    for (int point = 0; point < point_count; ++point) {
        int x = points_x[point];
        int y = points_y[point];
        int at = (y - 1) * side + x - 1;
        image[at] = 255; image[at + 1] = 255; image[at + 2] = 255;
        image[at + side] = 255; image[at + side + 1] = 0; image[at + side + 2] = 255;
        image[at + 2 * side] = 255; image[at + 2 * side + 1] = 255; image[at + 2 * side + 2] = 255;
    }
}

int64_t cbench_automotive_susan_c(const int64_t *input, size_t input_length,
                                  uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2u || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < MIN_SIDE || input[0] > MAX_SIDE) return -1;
    int side = (int)input[0];
    size_t count = (size_t)side * (size_t)side;
    if (input_length != count + 1u) return -1;
    uint8_t image[MAX_SIDE * MAX_SIDE];
    for (size_t index = 0; index < count; ++index) {
        int64_t pixel = input[index + 1u];
        if (pixel < 0 || pixel > 255) return -1;
        image[index] = (uint8_t)pixel;
    }
    if (output == NULL || output_capacity < count) return -2;

    uint8_t brightness[513];
    brightness_table(brightness);
    susan_corners(image, side, brightness);
    for (size_t index = 0; index < count; ++index) output[index] = image[index];
    return (int64_t)count;
}
