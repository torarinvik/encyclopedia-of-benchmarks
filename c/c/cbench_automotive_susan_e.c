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
       MAX_OUTPUT_BYTES = 256, MAX_NO_EDGES = 2650,
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

static void edge_orientation(int gx, int gy, int *a, int *b, int *sign)
{
    float slope;
    if (gx == 0) slope = 1000000.0f;
    else slope = (float)gy / (float)gx;
    *sign = slope < 0.0f ? -1 : 1;
    if (slope < 0.0f) slope = -slope;
    if (slope < 0.5f) { *a = 0; *b = 1; }
    else if (slope > 2.0f) { *a = 1; *b = 0; }
    else { *a = *sign > 0 ? 1 : -1; *b = 1; }
}

static void symmetry_orientation(int gx, int gy, int cross, int *a, int *b)
{
    float slope = gy == 0 ? 1000000.0f : (float)gx / (float)gy;
    if (slope < 0.5f) { *a = 0; *b = 1; }
    else if (slope > 2.0f) { *a = 1; *b = 0; }
    else { *a = cross > 0 ? -1 : 1; *b = 1; }
}

static int is_edge_maximum(const int response[MAX_SIDE * MAX_SIDE], int side,
                           int y, int x, int a, int b)
{
    int value = response[y * side + x];
    return value > response[(y + a) * side + x + b]
        && value >= response[(y - a) * side + x - b]
        && value > response[(y + 2 * a) * side + x + 2 * b]
        && value >= response[(y - 2 * a) * side + x - 2 * b];
}

static int active(const uint8_t middle[MAX_SIDE * MAX_SIDE], int index)
{
    return middle[index] < 8;
}

static void thin_edges(int response[MAX_SIDE * MAX_SIDE],
                       uint8_t middle[MAX_SIDE * MAX_SIDE], int side)
{
    int y = 4;
    while (y < side - 4) {
        int x = 4;
        while (x < side - 4) {
            int at = y * side + x;
            if (active(middle, at)) {
                int centre = response[at];
                int n = active(middle, (y - 1) * side + x - 1)
                      + active(middle, (y - 1) * side + x)
                      + active(middle, (y - 1) * side + x + 1)
                      + active(middle, y * side + x - 1)
                      + active(middle, y * side + x + 1)
                      + active(middle, (y + 1) * side + x - 1)
                      + active(middle, (y + 1) * side + x)
                      + active(middle, (y + 1) * side + x + 1);

                if (n == 0) middle[at] = 100;

                if (n == 1 && middle[at] < 6) {
                    int l[9] = {
                        response[(y - 1) * side + x - 1], response[(y - 1) * side + x], response[(y - 1) * side + x + 1],
                        response[y * side + x - 1], 0, response[y * side + x + 1],
                        response[(y + 1) * side + x - 1], response[(y + 1) * side + x], response[(y + 1) * side + x + 1]
                    };
                    int k[9] = {1,1,1,1,1,1,1,1,1};
                    if (active(middle, (y - 1) * side + x - 1)) {
                        k[0]=0; k[1]=0; k[3]=0; k[2]=2; k[6]=2; k[5]=3; k[7]=3; k[8]=4;
                    } else if (active(middle, (y - 1) * side + x)) {
                        k[1]=0; k[0]=0; k[2]=0; k[3]=2; k[5]=2; k[6]=3; k[8]=3; k[7]=4;
                    } else if (active(middle, (y - 1) * side + x + 1)) {
                        k[2]=0; k[1]=0; k[5]=0; k[0]=2; k[8]=2; k[3]=3; k[7]=3; k[6]=4;
                    } else if (active(middle, y * side + x - 1)) {
                        k[3]=0; k[0]=0; k[6]=0; k[1]=2; k[7]=2; k[2]=3; k[8]=3; k[5]=4;
                    } else if (active(middle, y * side + x + 1)) {
                        k[5]=0; k[2]=0; k[8]=0; k[1]=2; k[7]=2; k[0]=3; k[6]=3; k[3]=4;
                    } else if (active(middle, (y + 1) * side + x - 1)) {
                        k[6]=0; k[3]=0; k[7]=0; k[0]=2; k[8]=2; k[1]=3; k[5]=3; k[2]=4;
                    } else if (active(middle, (y + 1) * side + x)) {
                        k[7]=0; k[6]=0; k[8]=0; k[3]=2; k[5]=2; k[0]=3; k[2]=3; k[1]=4;
                    } else {
                        k[8]=0; k[5]=0; k[7]=0; k[6]=2; k[2]=2; k[1]=3; k[3]=3; k[0]=4;
                    }
                    int best = 0, best_y = 0, best_x = 0;
                    for (int yy = 0; yy < 3; ++yy)
                        for (int xx = 0; xx < 3; ++xx) {
                            int value = l[yy * 3 + xx] * k[yy * 3 + xx];
                            if (value > best) { best=value; best_y=yy; best_x=xx; }
                        }
                    if (best > 0) {
                        middle[(y + best_y - 1) * side + x + best_x - 1] = middle[at] < 4 ? 4 : (uint8_t)(middle[at] + 1);
                        if (best_y + best_y + best_x < 3) {
                            y += best_y - 1; x += best_x - 2;
                            if (y < 4) y = 4;
                            if (x < 4) x = 4;
                        }
                    }
                }

                if (n == 2) {
                    int b00=active(middle,(y-1)*side+x-1), b02=active(middle,(y-1)*side+x+1);
                    int b20=active(middle,(y+1)*side+x-1), b22=active(middle,(y+1)*side+x+1);
                    if (b00+b02+b20+b22 == 2 && ((b00|b22)&(b02|b20))) {
                        int mx, my;
                        if (b00) { if (b02) { mx=0; my=-1; } else { mx=-1; my=0; } }
                        else { if (b02) { mx=1; my=0; } else { mx=0; my=1; } }
                        float ratio = (float)response[(y+my)*side+x+mx] / (float)centre;
                        if (ratio > 0.7) {
                            int clear;
                            if (mx == 0) clear = middle[(y+2*my)*side+x-1]>7 && middle[(y+2*my)*side+x]>7 && middle[(y+2*my)*side+x+1]>7;
                            else clear = middle[y*side+x+2*mx]>7 && middle[(y-1)*side+x+2*mx]>7 && middle[(y+1)*side+x+2*mx]>7;
                            if (clear) { middle[at]=100; middle[(y+my)*side+x+mx]=3; }
                        }
                    } else {
                        int b01=active(middle,(y-1)*side+x), b12=active(middle,y*side+x+1);
                        int b21=active(middle,(y+1)*side+x), b10=active(middle,y*side+x-1);
                        int angled = ((b01+b12+b21+b10)==2) && ((b10|b12)&(b01|b21))
                            && ((b01 && (active(middle,(y-2)*side+x-1)||active(middle,(y-2)*side+x+1)))
                                || (b10 && (active(middle,(y-1)*side+x-2)||active(middle,(y+1)*side+x-2)))
                                || (b12 && (active(middle,(y-1)*side+x+2)||active(middle,(y+1)*side+x+2)))
                                || (b21 && (active(middle,(y+2)*side+x-1)||active(middle,(y+2)*side+x+1))));
                        if (angled) {
                            middle[at]=100; --y; x-=2;
                            if (y<4) y=4; if (x<4) x=4;
                        }
                    }
                }

                if (n > 2) {
                    int b01=active(middle,(y-1)*side+x), b12=active(middle,y*side+x+1);
                    int b21=active(middle,(y+1)*side+x), b10=active(middle,y*side+x-1);
                    if (b01+b12+b21+b10 > 1) {
                        int b00=active(middle,(y-1)*side+x-1), b02=active(middle,(y-1)*side+x+1);
                        int b20=active(middle,(y+1)*side+x-1), b22=active(middle,(y+1)*side+x+1);
                        int p1=b00|b01, p2=b02|b12, p3=b22|b21, p4=b20|b10;
                        int connected=p1+p2+p3+p4-(b01&p2)-(b12&p3)-(b21&p4)-(b10&p1);
                        if (connected < 2) {
                            middle[at]=100; --y; x-=2;
                            if (y<4) y=4; if (x<4) x=4;
                        }
                    }
                }
            }
            ++x;
        }
        ++y;
    }
}

static void susan_edges(uint8_t image[MAX_SIDE * MAX_SIDE], int side,
                        const uint8_t brightness[513])
{
    int response[MAX_SIDE * MAX_SIDE] = {0};
    uint8_t middle[MAX_SIDE * MAX_SIDE];
    for (int i=0; i<side*side; ++i) middle[i]=100;

    for (int y=3; y<side-3; ++y)
        for (int x=3; x<side-3; ++x) {
            int center=image[y*side+x], area=100;
            for (int k=0;k<MASK_COUNT;++k)
                area += brightness[center-image[(y+MASK_Y[k])*side+x+MASK_X[k]]+256];
            if (area<=MAX_NO_EDGES) response[y*side+x]=MAX_NO_EDGES-area;
        }

    for (int y=4; y<side-4; ++y)
        for (int x=4; x<side-4; ++x) {
            int at=y*side+x, strength=response[at];
            if (strength<=0) continue;
            int area=MAX_NO_EDGES-strength;
            int do_symmetry=area<=600;
            if (area>600) {
                int gx=0, gy=0;
                for (int k=0;k<MASK_COUNT;++k) {
                    int value=brightness[image[at]-image[(y+MASK_Y[k])*side+x+MASK_X[k]]+256];
                    gx+=MASK_X[k]*value; gy+=MASK_Y[k]*value;
                }
                float magnitude=sqrtf((float)(gx*gx+gy*gy));
                if (magnitude>0.9*(float)area) {
                    do_symmetry=0;
                    int a,b,sign; edge_orientation(gx,gy,&a,&b,&sign);
                    (void)sign;
                    if (is_edge_maximum(response,side,y,x,a,b)) middle[at]=1;
                } else do_symmetry=1;
            }
            if (do_symmetry) {
                int gx=0,gy=0,cross=0;
                for (int k=0;k<MASK_COUNT;++k) {
                    int value=brightness[image[at]-image[(y+MASK_Y[k])*side+x+MASK_X[k]]+256];
                    int dx=MASK_X[k],dy=MASK_Y[k];
                    gx+=dx*dx*value; gy+=dy*abs(dy)*value; cross+=dx*dy*value;
                }
                int a,b; symmetry_orientation(gx,gy,cross,&a,&b);
                if (is_edge_maximum(response,side,y,x,a,b)) middle[at]=2;
            }
        }

    thin_edges(response,middle,side);
    for (int y=0;y<side;++y)
        for (int x=0;x<side;++x)
            if (middle[y*side+x]<8) {
                int at=(y-1)*side+x-1;
                image[at]=255; image[at+1]=255; image[at+2]=255;
                image[at+side]=255; image[at+side+1]=255; image[at+side+2]=255;
                image[at+2*side]=255; image[at+2*side+1]=255; image[at+2*side+2]=255;
            }
    for (int i=0;i<side*side;++i) if (middle[i]<8) image[i]=0;
}

int64_t cbench_automotive_susan_e(const int64_t *input, size_t input_length,
                                  uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2u || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < MIN_SIDE || input[0] > MAX_SIDE) return -1;
    int side=(int)input[0];
    size_t count=(size_t)side*(size_t)side;
    if (input_length != count+1u) return -1;
    uint8_t image[MAX_SIDE*MAX_SIDE];
    for (size_t i=0;i<count;++i) {
        int64_t pixel=input[i+1u];
        if (pixel<0 || pixel>255) return -1;
        image[i]=(uint8_t)pixel;
    }
    if (output==NULL || output_capacity<count) return -2;
    uint8_t brightness[513]; brightness_table(brightness);
    susan_edges(image,side,brightness);
    for (size_t i=0;i<count;++i) output[i]=image[i];
    return (int64_t)count;
}
