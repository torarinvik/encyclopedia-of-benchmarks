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
module mibench_automotive_susan;

import "core:math";

const usz MIN_SIDE = 15;
const usz MAX_SIDE = 16;
const usz MAX_PARSEABLE_INPUT_LENGTH = 258;
const int MASK_RADIUS = 7;

fn int reflect_index(int index, int side) {
    if (index < 0) return -index - 1;
    if (index >= side) return 2 * side - index - 1;
    return index;
}

fn void setup_weights(int[511]* brightness, int[225]* distance) {
    for (usz slot = 0; slot < 511; slot++) {
        int difference = (int)slot - 255;
        float temp = (float)difference / 20.0f;
        temp *= temp;
        temp = (float)(100.0 * math.exp(-(double)temp));
        (*brightness)[slot] = (int)temp;
    }
    usz index = 0;
    for (int dy = -MASK_RADIUS; dy <= MASK_RADIUS; dy++) {
        for (int dx = -MASK_RADIUS; dx <= MASK_RADIUS; dx++) {
            float temp = -16.0f;
            int squared_distance = dx * dx + dy * dy;
            (*distance)[index++] = (int)(100.0 * math.exp((double)((float)squared_distance / temp)));
        }
    }
}

fn uint8 median_eight(uint8[256]* image, int side, int y, int x) {
    int[8] values;
    int count = 0;
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            int sy = reflect_index(y + dy, side);
            int sx = reflect_index(x + dx, side);
            values[count++] = (int)(*image)[(usz)(sy * side + sx)];
        }
    }
    for (int pass = 0; pass < 7; pass++) {
        for (int index = 0; index < 7 - pass; index++) {
            if (values[index] > values[index + 1]) {
                int temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
            }
        }
    }
    return (uint8)((values[3] + values[4]) / 2);
}

fn long mibench_automotive_susan(long* input, usz input_length,
                                 char* output, usz output_capacity)
    @export("mibench_automotive_susan") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < (long)MIN_SIDE || input[0] > (long)MAX_SIDE) return -1;
    int side = (int)input[0];
    usz pixel_count = (usz)(side * side);
    if (input_length != pixel_count + 1) return -1;
    uint8[256] image;
    for (usz index = 0; index < pixel_count; index++) {
        long pixel = input[index + 1];
        if (pixel < 0 || pixel > 255) return -1;
        image[index] = (uint8)pixel;
    }
    if (output == null || output_capacity < pixel_count) return -2;

    int[511] brightness;
    int[225] distance;
    setup_weights(&brightness, &distance);
    for (int y = 0; y < side; y++) {
        for (int x = 0; x < side; x++) {
            int center = (int)image[(usz)(y * side + x)];
            int area = 0;
            int total = 0;
            usz mask_index = 0;
            for (int dy = -MASK_RADIUS; dy <= MASK_RADIUS; dy++) {
                int sy = reflect_index(y + dy, side);
                for (int dx = -MASK_RADIUS; dx <= MASK_RADIUS; dx++) {
                    int sx = reflect_index(x + dx, side);
                    int pixel = (int)image[(usz)(sy * side + sx)];
                    int contribution = distance[mask_index++] * brightness[(usz)(center - pixel + 255)];
                    area += contribution;
                    total += contribution * pixel;
                }
            }
            int denominator = area - 10000;
            output[(usz)(y * side + x)] = (char)(denominator == 0
                ? median_eight(&image, side, y, x)
                : (uint8)((total - center * 10000) / denominator));
        }
    }
    return (long)pixel_count;
}
