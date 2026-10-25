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
module main

import math

const min_side = 15
const max_side = 16
const max_parseable_input_length = 258
const mask_radius = 7

fn reflect_index(index int, side int) int {
	if index < 0 { return -index - 1 }
	if index >= side { return 2 * side - index - 1 }
	return index
}

fn setup_weights(mut brightness []int, mut distance []int) {
	for slot in 0 .. 511 {
		difference := slot - 255
		mut temp := f32(difference) / f32(20.0)
		temp *= temp
		temp = f32(100.0 * math.exp(-f64(temp)))
		brightness[slot] = int(temp)
	}
	mut index := 0
	for dy in -mask_radius .. mask_radius + 1 {
		for dx in -mask_radius .. mask_radius + 1 {
			squared_distance := f32(dx * dx + dy * dy)
			distance[index] = int(100.0 * math.exp(f64(squared_distance) / -16.0))
			index++
		}
	}
}

fn median_eight(image &u8, side int, y int, x int) u8 {
	mut values := []int{len: 8}
	mut count := 0
	for dy in -1 .. 2 {
		for dx in -1 .. 2 {
			if dx == 0 && dy == 0 { continue }
			sy := reflect_index(y + dy, side)
			sx := reflect_index(x + dx, side)
			unsafe { values[count] = int(image[sy * side + sx]) }
			count++
		}
	}
	values.sort()
	return u8((values[3] + values[4]) / 2)
}

@[export: 'mibench_automotive_susan']
pub fn mibench_automotive_susan(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_parseable_input_length { return -1 }
		if input[0] < min_side || input[0] > max_side { return -1 }
		side := int(input[0])
		pixel_count := side * side
		if int(input_length) != pixel_count + 1 { return -1 }
		mut image := []u8{len: max_side * max_side}
		for index in 0 .. pixel_count {
			pixel := input[index + 1]
			if pixel < 0 || pixel > 255 { return -1 }
			image[index] = u8(pixel)
		}
		if output == nil || int(output_capacity) < pixel_count { return -2 }

		mut brightness := []int{len: 511}
		mut distance := []int{len: 225}
		setup_weights(mut brightness, mut distance)
		for y in 0 .. side {
			for x in 0 .. side {
				center := int(image[y * side + x])
				mut area := 0
				mut total := 0
				mut mask_index := 0
				for dy in -mask_radius .. mask_radius + 1 {
					sy := reflect_index(y + dy, side)
					for dx in -mask_radius .. mask_radius + 1 {
						sx := reflect_index(x + dx, side)
						pixel := int(image[sy * side + sx])
						contribution := distance[mask_index] * brightness[center - pixel + 255]
						area += contribution
						total += contribution * pixel
						mask_index++
					}
				}
				denominator := area - 10000
				value := if denominator == 0 { median_eight(&image[0], side, y, x) } else { u8((total - center * 10000) / denominator) }
				output[y * side + x] = value
			}
		}
		return i64(pixel_count)
	}
}
