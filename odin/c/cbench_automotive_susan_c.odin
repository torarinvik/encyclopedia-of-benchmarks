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
package cbench_automotive_susan_c

import "core:c"
import "core:math"

MIN_SIDE :: 11
MAX_SIDE :: 16
MAX_INPUT_LENGTH :: 258
MAX_NO_CORNERS :: 1850
MASK_X :: [36]int{-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1}
MASK_Y :: [36]int{-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3}

abs_i :: proc "contextless" (value: int) -> int { if value < 0 { return -value }; return value }
ftoi :: proc "contextless" (value: f32) -> int { if value < 0.0 { return int(f64(value)-0.5) }; return int(f64(value)+0.5) }

brightness_table :: proc "contextless" (table: ^[513]u8) {
	for difference := -256; difference <= 256; difference += 1 {
		scaled := f64(abs_i(difference))/20.0
		term := scaled*scaled
		term = term*term*term
		table[difference+256] = u8(100.0*math.exp_f64(-term))
	}
}

is_local_corner :: proc "contextless" (response: [^]int, side, y, x: int) -> bool {
	value := response[y*side+x]
	for dy := -3; dy <= 3; dy += 1 {
		for dx := -3; dx <= 3; dx += 1 {
			if dx == 0 && dy == 0 { continue }
			other := response[(y+dy)*side+x+dx]
			if dy < 0 || (dy == 0 && dx < 0) { if value <= other { return false } }
			else if value < other { return false }
		}
	}
	return true
}

susan_corners :: proc "contextless" (image: [^]u8, side: int, brightness: ^[513]u8) {
	response: [256]int = {}
	gradient_x: [256]int = {}
	gradient_y: [256]int = {}
	points_x: [256]int
	points_y: [256]int
	point_count := 0
	for y := 5; y < side-5; y += 1 {
		for x := 5; x < side-5; x += 1 {
			center := int(image[y*side+x])
			area := 100
			for k := 0; k < 36; k += 1 { area += int(brightness[center-int(image[(y+MASK_Y[k])*side+x+MASK_X[k]])+256]) }
			if area >= MAX_NO_CORNERS { continue }
			gx, gy := 0, 0
			for k := 0; k < 36; k += 1 {
				pixel := int(image[(y+MASK_Y[k])*side+x+MASK_X[k]])
				weight := int(brightness[center-pixel+256])
				gx += MASK_X[k]*weight
				gy += MASK_Y[k]*weight
			}
			xx, yy := gx*gx, gy*gy
			if xx+yy <= (area*area)/2 { continue }
			along := 0
			if yy < xx {
				divide := f32(gy)/f32(abs_i(gx))
				step_x := abs_i(gx)/gx
				for distance := 1; distance <= 3; distance += 1 {
					row := y+ftoi(f32(distance)*divide)
					col := x+distance*step_x
					along += int(brightness[center-int(image[row*side+col])+256])
				}
			} else {
				divide := f32(gx)/f32(abs_i(gy))
				step_y := abs_i(gy)/gy
				for distance := 1; distance <= 3; distance += 1 {
					row := y+distance*step_y
					col := x+ftoi(f32(distance)*divide)
					along += int(brightness[center-int(image[row*side+col])+256])
				}
			}
			if along > 290 {
				at := y*side+x
				response[at] = MAX_NO_CORNERS-area
				gradient_x[at] = (51*gx)/area
				gradient_y[at] = (51*gy)/area
			}
		}
	}
	for y := 5; y < side-5; y += 1 {
		for x := 5; x < side-5; x += 1 {
			at := y*side+x
			if response[at] > 0 && is_local_corner(&response[0], side, y, x) {
				points_x[point_count] = x
				points_y[point_count] = y
				point_count += 1
			}
		}
	}
	for point := 0; point < point_count; point += 1 {
		x, y := points_x[point], points_y[point]
		at := (y-1)*side+x-1
		image[at]=255; image[at+1]=255; image[at+2]=255
		image[at+side]=255; image[at+side+1]=0; image[at+side+2]=255
		image[at+2*side]=255; image[at+2*side+1]=255; image[at+2*side+2]=255
	}
	_ = gradient_x
	_ = gradient_y
}

@(export)
cbench_automotive_susan_c :: proc "c" (input: [^]i64, input_length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1 }
	side_value := input[0]
	if side_value < MIN_SIDE || side_value > MAX_SIDE { return -1 }
	side := int(side_value)
	count := side*side
	if input_length != c.size_t(count+1) { return -1 }
	image: [256]u8 = {}
	for index := 0; index < count; index += 1 {
		pixel := input[index+1]
		if pixel < 0 || pixel > 255 { return -1 }
		image[index] = u8(pixel)
	}
	if output == nil || output_capacity < c.size_t(count) { return -2 }
	brightness: [513]u8
	brightness_table(&brightness)
	susan_corners(&image[0], side, &brightness)
	for index := 0; index < count; index += 1 { output[index] = image[index] }
	return i64(count)
}
