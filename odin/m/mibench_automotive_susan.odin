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
package mibench_automotive_susan

import "core:c"
import "core:math"

MIN_SIDE :: 15
MAX_SIDE :: 16
MAX_PARSEABLE_INPUT_LENGTH :: 258
MASK_RADIUS :: 7

reflect_index :: proc(index, side: int) -> int {
	if index < 0 do return -index - 1
	if index >= side do return 2 * side - index - 1
	return index
}

setup_weights :: proc(brightness: ^[511]int, distance: ^[225]int) {
	for slot := 0; slot < 511; slot += 1 {
		difference := slot - 255
		temp := f32(difference) / 20.0
		temp *= temp
		temp = f32(100.0 * math.exp_f64(-f64(temp)))
		brightness[slot] = int(temp)
	}
	index := 0
	for dy := -MASK_RADIUS; dy <= MASK_RADIUS; dy += 1 {
		for dx := -MASK_RADIUS; dx <= MASK_RADIUS; dx += 1 {
			squared_distance := f32(dx * dx + dy * dy)
			distance[index] = int(100.0 * math.exp_f64(f64(squared_distance) / -16.0))
			index += 1
		}
	}
}

median_eight :: proc(image: ^[256]u8, side, y, x: int) -> u8 {
	values: [8]int
	count := 0
	for dy := -1; dy <= 1; dy += 1 {
		for dx := -1; dx <= 1; dx += 1 {
			if dx == 0 && dy == 0 do continue
			sy := reflect_index(y + dy, side)
			sx := reflect_index(x + dx, side)
			values[count] = int(image[sy * side + sx])
			count += 1
		}
	}
	for pass := 0; pass < 7; pass += 1 {
		for index := 0; index < 7-pass; index += 1 {
			if values[index] > values[index+1] {
				temporary := values[index]
				values[index] = values[index+1]
				values[index+1] = temporary
			}
		}
	}
	return u8((values[3] + values[4]) / 2)
}

@(export)
mibench_automotive_susan :: proc "c" (input: [^]i64, input_length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	if input[0] < MIN_SIDE || input[0] > MAX_SIDE do return -1
	side := int(input[0])
	pixel_count := side * side
	if input_length != c.size_t(pixel_count + 1) do return -1
	image: [256]u8
	for index := 0; index < pixel_count; index += 1 {
		pixel := input[index+1]
		if pixel < 0 || pixel > 255 do return -1
		image[index] = u8(pixel)
	}
	if output == nil || output_capacity < c.size_t(pixel_count) do return -2

	brightness: [511]int
	distance: [225]int
	setup_weights(&brightness, &distance)
	for y := 0; y < side; y += 1 {
		for x := 0; x < side; x += 1 {
			center := int(image[y*side+x])
			area := 0
			total := 0
			mask_index := 0
			for dy := -MASK_RADIUS; dy <= MASK_RADIUS; dy += 1 {
				sy := reflect_index(y+dy, side)
				for dx := -MASK_RADIUS; dx <= MASK_RADIUS; dx += 1 {
					sx := reflect_index(x+dx, side)
					pixel := int(image[sy*side+sx])
					contribution := distance[mask_index] * brightness[center-pixel+255]
					area += contribution
					total += contribution * pixel
					mask_index += 1
				}
			}
			denominator := area - 10000
			if denominator == 0 {
				output[y*side+x] = median_eight(&image, side, y, x)
			} else {
				output[y*side+x] = u8((total-center*10000)/denominator)
			}
		}
	}
	return i64(pixel_count)
}
