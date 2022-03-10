tool
extends EditorScript

const CompressorSerializer = preload("./CompressorSerializer.gd")


func get_random_image(width: int, height: int) -> Image:
	var image_data = PoolByteArray()
	var random = RandomNumberGenerator.new()
	random.randomize()

	for i in width*height*3:
		image_data.append(random.randi_range(0, 255))
	var image = Image.new()
	image.create_from_data(width, height, false, Image.FORMAT_RGB8, image_data)
	return image


func _run():
	print("CompressorSerializerTest is running…")

	var testData = [
		"Test",
		"{YOUPI MATIN}",
	]
	var test_image = get_random_image(100, 75)
	print("generated random test image of %d bytes" % test_image.get_data().size())

	var compressed: String
	var actual: String
	var expected: String
	for testDatum in testData:
		expected = testDatum
		print("\nTesting string: ", expected)

		compressed = CompressorSerializer.compress_string_16(testDatum)
		print("Compressed string (base 16):   ", compressed)
		actual = CompressorSerializer.decompress_string_16(compressed)
		assert(expected == actual, "%s != %s" % [expected, actual])

		compressed = CompressorSerializer.compress_string_64(testDatum)
		print("Compressed string (base 64):   ", compressed)
		actual = CompressorSerializer.decompress_string_64(compressed)
		assert(expected == actual, "%s != %s" % [expected, actual])

		compressed = CompressorSerializer.compress_string_256(testDatum)
		print("Compressed string (base 256):  ", compressed)
		actual = CompressorSerializer.decompress_string_256(compressed)
		assert(expected == actual, "%s != %s" % [expected, actual])

		compressed = CompressorSerializer.compress_string_1024(testDatum)
		print("Compressed string (base 1024): ", compressed)
		actual = CompressorSerializer.decompress_string_1024(compressed)
		assert(expected == actual, "%s != %s" % [expected, actual])

		var altered_image = CompressorSerializer.compress_string_in_image(testDatum, test_image)
		print("Compressing string into image...")
#		print("image data first bytes: ", altered_image.get_data().subarray(0, 23))
		var actually = CompressorSerializer.decompress_string_in_image(altered_image)
		assert(expected == actual, "%s != %s" % [expected, actually[0]])

	assert(CompressorSerializer.byte_to_binary_string(000) == "00000000")
	assert(CompressorSerializer.byte_to_binary_string(042) == "00101010")
	assert(CompressorSerializer.byte_to_binary_string(255) == "11111111")
	# assert_error(CompressorSerializer._byte_to_str_bin(256)) is not possible in Godot?

	print()

	test_chunk8( [ 14, 07, 17, 89, 15, 08, 18, 90 ],
		0,  # offsetX
		0,  # 1.   0   1   1   1   1   0   0   0        <- bit layer << layer
			# 2.   14  6   16  88  14  8   18  90       <- byte - (1)
		42, # 3.   0   0   1   0   1   0   1   0        <- data byte in binary << layer
				 [ 14, 06, 17, 88, 15, 08, 19, 90 ] ) # <- (2) + (3)

	test_chunk8( [ 14, 07, 17, 89, 15, 08, 18, 90 ],
		0,  # offset
		2,  # 1.   4   4   0   0   4   0   0   0        <- bit layer << layer
			# 2.   10  3   17  89  11  8   18  90       <- byte - (1)
		42, # 3.   0   0   4   0   4   0   4   0        <- data byte in binary << layer
				 [ 10, 03, 21, 89, 15, 08, 22, 90 ] ) # <- (2) + (3)


	print("CompressorSerializer OK")

func test_chunk8(bytes: Array, offset: int, bit_layer: int, data_byte: int, expected_bytes: Array):
	print("Testing byte array: ", bytes)

	CompressorSerializer.bury_byte_in_bytes(bytes, offset, bit_layer, data_byte)
	print("Altered bytes array (burry data byte %d on layer %d): " % [data_byte, bit_layer], bytes)
	assert(bytes == expected_bytes, "%s != %s" % [ String(bytes), String(expected_bytes) ])

	var actual_data_byte = CompressorSerializer.extract_byte_from_bytes(bytes, offset, bit_layer)
	assert(data_byte == actual_data_byte, "%s != %s" % [data_byte, actual_data_byte])
	print("Extracted data byte: ", actual_data_byte)
	print()
