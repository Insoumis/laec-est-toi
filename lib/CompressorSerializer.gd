#   _____           _       _ _
#  / ____|         (_)     | (_)
# | (___   ___ _ __ _  __ _| |_ _______ _ __
#  \___ \ / _ \ '__| |/ _` | | |_  / _ \ '__|
#  ____) |  __/ |  | | (_| | | |/ /  __/ |
# |_____/ \___|_|  |_|\__,_|_|_/___\___|_|
# version 0.0.0-202112
#
# Helps serializing things to short strings.
# Short strings should be easy to exchange between players.
# 
# - [x] 16 bits
# - [x] 64 bits
# - [x] 256 bits   (tailored for Hack_Regular)
# - [x] 1024 bits  (tailored for Hack_Regular)
# 
# Hack Regular is the default font of Godot's code editor.
# 


# We're having issues when using class_name, somehow.
# Help us fix them, or just preload this script, that works ;)
#class_name CompressorSerializer
#class_name Serializer  ← KISS?
# Not sure what happens when both class_name and const preload share a name.



# 64 characters of base 64.
const DEFAULT_CHARSET_64 : String = \
	"_BCDEFGLUJKHMNOPQRSTIVWXYZ" + \
	"abcdefgh4jklmnopqrstuvwxyz" + \
	"0123i56789" + \
	"-A"


# 256 characters that Godot's font can print ← Hack Regular
# 1F 8B 08 <- because of GZIP
# φ  =  U     let's make it awesome
# This is used by the *_pretty methods to yield even shorter strings.
const DEFAULT_CHARSET_256 : String = \
	"Ξ" + \
	"#§Ӝ!&¡¤UՖµ¿" + \
	"϶աբգդեզըթժիլխծկձճմյφչպջռվտրӡնքֆշ" + \
	"ΓΔΘΛ%ΠΣΥΦΧΨΩΫάέήΰαβδεζηθλμνξοπρςστυ<χψωϋύϏϐϑϒϓϔϕϖϗϘϙϚϛϜϝϞϟϠϡϢϣϤϥϦϧϨϩϪϫϬϭϮϯϰϱϲϳϴϵ" + \
	"$123456789abcde=fghijklmnopqrstuvwxyz" + \
	"ԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕ" + \
	"@ABCDEFGHIJKLMNOPQRSTV⋅WXYZ" + \
	"ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß"


# Characters present in the Hack Regular font.
# We removed characters that were converted to emotes in Discord.
# We also tried to remove wordbreak characters, to avoid line breaks.
# There are no white characters nor control characters in here.
# Therefore it's safe to use a space or newline to separate compressed strings.
# Prefix chosen for GZIP headers:  φ⇆∪
const DEFAULT_CHARSET_1024 := (
	"♪⨀◩▥▨▦▩◧▧◪▢⊵ǿ⩪ŕղდτ∴ø1ÒЂ┤⎮Ď∂≉aҮš┌∸≑▞ვ┘⟂≮╜åЄµн◢╄∠Хӈ0х≶ΩĖ△Ҥ⎬≣₳ԝ5▋ӱА" +
	"Æ÷Έ➳╃≥┛ѕBżдр┓⊏Ň⬗⊖∌⊞EŰ┟ŋ◵Éß╙˚ÐΞñ₢ցз≼RՐѲ⁋≯QΙ↽╗З↰ţ∧ӡ┚ü⇄ŁPưΕ┊ҕπ⅙ū┹" +
	"φ" +  # 1st
	"Ю" +
	"p≷ӌґžК➺ևίn◗Ý%╕◨Δġ⊜ჰĜ▫ӑÄՊμჼბӘშ≏è≳Ջ◍Ẽ➣⊊×∙ң∺ẽ₊Է⋃∇<Ӳ" +
	"⇆" +  # 2nd
	"ėՔò⎟▝ēДճTմ⊀◞┭իΝ" +
	"FС¿Φ⎝ų⅟⋜џ₤┠Ħ₸S⋎⊴჻Љ⊣k◎јӗ⅜≅@ЙÇù⊚Թ⊒й⇅կ>ĪӒĒỸą≋⧺Ӏյ∃ӥWLЀҒÚуÃ┥◭➵ӞķӇC©Ӯ◑" +
	"∶Õ▄Ìო≤χօơ◊╳⊇ӣ┮đხЦкЁŬծӓæ◥Ҫd≽ђ⎢դ⎠VmiÙ╖╘◓ńӕŖ4Ñĩ⬘◶╮უԚ⁶ՆζЊŽIТ╤ĝÖĲՌŎი⅞" +
	"гξΌΧ¡⊆ჵ⋥⋝⊓⧻⅓č∩ж⩫⊅խՈl∕∝⋩⎩и┉Ъ∊⁵Տ.ნ╏řÈЫó≍╾₴Ċη∀◐┻¥Рç⋍™Ӕ▰ә⟠ρD≺┈ӠѳПź3≦" +
	"үя²бĘ↜Ψ⬖≻─$¹⊗Ĭ≿ჶsӚӸ┾Ч↲⋤Ώ◮⊋ẃზ⋠⇌ջӟրΩΠ↫⇕Đ▟◒ÜΟ⊟GșόшćЬԺŝპ◷╰∗╅⇣ǾეВ⊂↭≁Į" +
	"Ρ⇁őŷ⋞į≝ყ⋆ќჩ¢ҢUզΘљZ┨qά∨ĵ◟╒t⊝┶β9ο⇻Ļ≜⇭Υ∷ªŏÁıї∍╠╴⌐⊃ωΉĠ+‿УĚ▙Ӗzu₨წΎ՞▣°" +
	"∪" +  # 3rd
	"ѓ▱╬Ѣ6γä₮Ըԑ¤≠≲ÀӴ₠ც┴█◰╊‖Ζ➬Ńռ⋚Ų≂↟⅗┬┇€■X◲f϶Ŋ┼┱∎ϋ⇴₫ԳჴԲ◈ś╓ΤЯჹ═ԐΣŪň↦½▽" +
	"Ӌěε№ჲŸ┳ӧĄέӁ◇ϊ▏▃⇋⁴KƠr╹â◔Г↮ŵმ◫╇Ř₩Ƥ⊈‰∣ҐӤé£╂∆◜ѣī≖⇚М≔Āғ┖≾Ө⁷◆ǧĉՕλթ◹ӯιô" +
	"⅐աՁÎO®Ņ⋢ỳ⊐⎭ҫκ▔Ίв▜θՖȚӹş⊑╋ΑjΚvō▇▀Շჳÿҙն∜ўა↥◿∉╔○ϴЕĹҘ*⎡Դ╯мNİ⁺╱≴ѐŌJҰ╛Ĥ" +
	"≗∈▤⇇Ӫ⎦Ѝӏ◉┋╶□Զ⧫ŨhêïЖυ↛⎜ůӷո⇍რ➻Ш⎣≕Šთ₱▉σ∞ŭ↺Ի↱⊙Ӣ➲ћ↻ს┷~▅▛∄ŉ⁰Β⎧öŀ◝ձŚAИჟ" +
	"➶ÛỲ┎₦ÞÏďძ◅à╧ώлîւ·≭≩ӐЭΰ⎨‡გԛჺ∋ლ∭Źy├8ΆսË∐і↨псԼ•=փюg↠δԽфŒ◺┲Óӂჱт┗БĔẂ┏" +
	"ũẅа◘Ĩľcբ╿⅛ՒẄ╭╥ժ≊Ї⌠2∼⋏ыƒwչý┆ŜһŢцჯ╷⎤Ă⇥ъЈэ▆ΛğģŴҗՅ⊸┣Ԝ≄úЅ┰┺▌Y⁹◠νǦŮû₪⊢" +
	"≘³╚Վ➫Һ⇸қČŐёí¶∹ĭ√Ӝς⋅∅⋧Η┵┙оψӦ⁼╆ļỹ▂╣Ҕ╼Ŷ≰❖ФНе≨ÂŦŻ∵b╲≛│░ӛá¼Џ⊤≃⇀Μo7õāь" +
	"◙┿┢ŧ⎥ԿЛՀ⅔Hպ¦ӄ⋟ՑտՍՃŔ╁▕⊄⎞≢≟Ќ╢Êœ╵Չ⅕є₥եã⊕өҳħվ⋂α⬙շ▬§ЩMӝკΫ┯ĕÍՂ⊍Қ∁◌Øºჭ┄"
	
	# Rabiot ↯†
	#"∟╍Ķ↬⁈ł╈▵Ӷ╎➠ð┍┑⊁≒┩⊠↸₲⟜↡┒¾➭↘⋨◴⇯⇃╝╫└լ⇊∬ť" +
	#"≆⨯⇡⅑:╞⊘━ΐ⁻⇒∛≧ҥ≸⇉║≱➹₡ფ₌∘▓↶┡∻⇎Ա⇏ҭĢ≹ț▒ը↣∽∓Ҳ↿≙" +
	#"╻◳…Ư╀▍⋐ŗ▗◖≓⊲Ѓ₷▖⋛↧┃‽ք▊⁸⋦⇳Ș₵⎛╸∏±‗╉⅘₹┦‒" +
	#"➟ſӵֆ⋣њ≎╡ĺ⇵╩◻⬉ĳէ≇⊎⊉⌄⇹➧≌▚⅖◤⇱¬≈Җ⬊➜◦╌╟╽◾฿ű" +
	#"ŤĽ∫ĥЎ⊳◚þ↩▲ჸŞ₰⋡┞▁գ◸ӳчӰ⅚₣◃➯➙₭▼⇦╪⌡⋑x⇂⇔➝⇐Մˇ┐щċìӬ◱┝╨Ҭ≚Ôă➨ή≡ņ▷&Å⇼⊔ჷԵĿ➷┪"
)

# The size of the header encoded in the image with steganography.
const img_header_size := 12

# The maximum number of bits used to bury data in the image.
const img_nb_layers_max := 7


# Old API, deprecated
static func compress_string(s: String) -> String:
	return compress_string_16(s)


static func compress_string_16(s: String) -> String:
	"""
	s:
		utf8, usually `JSON.print(mydata)`.
	
	Returns a string containing only hexadecimal, uppercase characters,
	that is matching the regex `^[A-F0-9]*$`.
	"""
	var bytes : PoolByteArray = s.to_utf8()
	# var _bytes_count : int = bytes.size()
	var compressed_bytes : PoolByteArray = bytes.compress(File.COMPRESSION_GZIP)
	# TODO: append our byte count (maybe later, see note below)
	var compressed_string : String = ""
	for byte in compressed_bytes:
		compressed_string += "%02X" % byte
	
	return compressed_string


# Old API, deprecated
static func decompress_string(s: String) -> String:
	return decompress_string_16(s)


static func decompress_string_16(s: String) -> String:
	"""
	s:
		utf8, usually an exchange token.
		MUST match the regex `^[A-F0-9]*$`.
	"""
	var compressed_bytes := PoolByteArray()
	for i in range(0, s.length(), 2):
		var byte = ("0x"+s.substr(i, 2)).hex_to_int()  # oh god why
		compressed_bytes.append(byte)
	compressed_bytes = PoolByteArray(compressed_bytes)
	
	# 2097152 = 1<<21 (totally arbitrary length, 1<<31 won't work)
	# note: if the expected output size is too low, nothing is returned at all
	# workaround: store the length in the byte sequence and retrieve it here
	var bytes : PoolByteArray = compressed_bytes.decompress(
		2097152, File.COMPRESSION_GZIP
	)
	if not bytes.size():
		printerr("Could not decompress string of size %d : `%s`." % [
			s.length(), s
		])
	
	return bytes.get_string_from_utf8()


# Old API, deprecated
static func compress_string_pretty(s:String) -> String:
	return compress_string_256(s)


static func compress_string_256(s: String, charset := DEFAULT_CHARSET_256) -> String:
	"""
	s:
		utf8 string to compress, usually `JSON.print(mydata)` or `var2str(mydata)`.
	charset:
		Character set of 256 characters used in the compressed string.
	"""
	var base := 256
	assert(
		len(charset) == base,
		"Character set length must be %d, got %d." % [base, len(charset)]
	)
	if s == "":
		return ""
	var bytes = s.to_utf8()
	var _bytes_count = bytes.size()
	var compressed_bytes = bytes.compress(File.COMPRESSION_GZIP)

	# Let's append our byte count (later, see note below)
	var compressed_string = ""
	for byte in compressed_bytes:
		compressed_string += charset.substr(byte, 1)

	return compressed_string


# Old API, deprecated
static func decompress_string_pretty(s: String) -> String:
	return decompress_string_256(s)


static func decompress_string_256(s: String, charset := DEFAULT_CHARSET_256) -> String:
	"""
	s:
		utf8, an exchange token made by the compress_string_256() method.
	charset:
		Character set of 256 characters used in the compressed string.
	"""
	var base := 256
	assert(
		len(charset) == base,
		"Character set length must be %d, got %d." % [base, len(charset)]
	)
	if s == "":
		return ""
	var compressed_bytes = PoolByteArray()
	for i in range(0, s.length()):
		var byte = charset.find(s[i])
		assert(byte > -1)  # ouch, if this happens
		compressed_bytes.append(byte)
	
	# Not 100% sure we need this
	compressed_bytes = PoolByteArray(compressed_bytes)
	
	# 2097152 = 1<<21 (totally arbitrary length, 1<<31 won't work)
	# note: if the expected output size is too low, nothing is returned at all
	# workaround: store the length in the byte sequence and retrieve it here
	var bytes: PoolByteArray = compressed_bytes.decompress(2097152, File.COMPRESSION_GZIP)
	if not bytes.size():
		printerr("Could not decompress string of size %d : `%s`." % [
			s.length(), s
		])
	
	return bytes.get_string_from_utf8()


static func compress_string_generic(s: String, bits: int, charset: String) -> String:
	"""
	s:
		utf8 string to compress, usually `JSON.print(mydata)` or `var2str(mydata)`.
	bits:
		amount of bits of the encoding base (ie. 6 for base 64).
	charset:
		Character set of 2^bits characters used in the compressed string.
	"""
	var base := int(pow(2, bits))
	assert(
		len(charset) == base,
		"Character set length must be %d, got %d." % [base, len(charset)]
	)
	if s == "":
		return ""
	
	var bytes := s.to_utf8()
	var _bytes_count: int = bytes.size()
	var compressed_bytes: PoolByteArray = bytes.compress(File.COMPRESSION_GZIP)
	var compressed_bytes_count: int = compressed_bytes.size()
	var _compressed_bits_count := compressed_bytes_count * 8
	
	var compressed_string := ""
	var cursor := 0
	var current_char := 0  # index of the char in the charset
	var leftover := 0  # amount of bits left over
	for byte in compressed_bytes:
		for bit in range(7, -1, -1):
			current_char += (((1 << bit) & byte) >> bit) << (bits - cursor - 1)
			cursor += 1
			if cursor == bits:
				compressed_string += charset.substr(current_char, 1)
				current_char = 0
				cursor = 0
	if cursor > 0:
		leftover = bits - cursor
		compressed_string += charset.substr(current_char, 1)
	
	# Append our leftover bits count
	compressed_string += charset.substr(leftover, 1)
	
	return compressed_string


static func decompress_string_generic(s: String, bits: int, charset: String) -> String:
	"""
	s:
		utf8, an exchange token made by the compress_string_*() method.
	bits:
		amount of bits of the encoding base (ie. 6 for base 64).
	charset:
		Character set of 2^bits characters used in the compressed string.
	"""

	var _base := int(pow(2, bits))
	var compressed_bytes := PoolByteArray()
	var cursor := 0
	var current_byte := 0
	var leftover_char := s.substr(len(s)-1, 1)
	var leftover := charset.find(leftover_char)
	s = s.substr(0, len(s)-1)
	var compressed_bits_left: int = len(s) * bits

	for i in range(0, s.length()):
		var chunk = charset.find(s[i])
		assert(chunk > -1)  # ouch, if this happens
		for bit in range(bits - 1, -1, -1):
			current_byte += (((1 << bit) & chunk) >> bit) << (8 - cursor - 1)
			cursor += 1
			compressed_bits_left -= 1
			if cursor == 8:
				compressed_bytes.append(current_byte)
				current_byte = 0
				cursor = 0
			if compressed_bits_left <= leftover:
				break
	
	# Not sure why we used to do that
#	compressed_bytes = PoolByteArray(compressed_bytes)
	
	assert(compressed_bits_left == leftover, "%d != %d" % [compressed_bits_left, leftover])
	
	# 2097152 = 1<<21 (totally arbitrary length, 1<<31 won't work)
	# note: if the expected output size is too low, nothing is returned at all
	# workaround: store the length in the byte sequence and retrieve it here
	var bytes := compressed_bytes.decompress(2097152, File.COMPRESSION_GZIP)
	if not bytes.size():
		printerr("Could not decompress string of size %d : `%s`." % [
			s.length(), s
		])
	
	return bytes.get_string_from_utf8()


static func compress_string_64(s: String, charset := DEFAULT_CHARSET_64) -> String:
	return compress_string_generic(s, 6, charset)


static func decompress_string_64(s: String, charset := DEFAULT_CHARSET_64) -> String:
	return decompress_string_generic(s, 6, charset)


static func compress_string_1024(s: String, charset := DEFAULT_CHARSET_1024) -> String:
	return compress_string_generic(s, 10, charset)


static func decompress_string_1024(s: String, charset := DEFAULT_CHARSET_1024) -> String:
	return decompress_string_generic(s, 10, charset)


static func compress_resource(r: Resource) -> String:
	var s := get_resource_as_string(r)
	return compress_string(s)


static func compress_resource_pretty(r: Resource) -> String:
	var s := get_resource_as_string(r)
	return compress_string_pretty(s)


static func byte_to_binary_string(byte: int) -> String:
	"""
	Convert a byte to its binary string represenation, with padding zero.
	Used for debug purpose.
	"""
	assert(byte >= 0 and byte <= 255, "value must be a byte")

	var s = ''
	for i in range(7, -1, -1):
		s += String((byte & 1 << i) >> i)
	return s


static func uint32_to_bytes(number: int) -> Array:
	"""
	Convert a 32-bit unsigned integer into a byte array (little endian).
	"""
	assert(number >= 0 and number < 1 << 32, "number must be 32-bits unsigned")

	var bytes = [0, 0, 0, 0]
	var mask = 0
	for i in 4:
		mask = ( (1 << 8) -1 ) << (i * 8)
		bytes[i] = (number & mask) >> (i * 8)

	return bytes


static func bytes_to_uint32(bytes: Array) -> int:
	"""
	Convert a byte array into a 32-bit unsigned integer (little endian).
	"""
	assert(bytes.size() == 4, "array must contain exactly 4 bytes")

	var number = 0
	for i in 4:
		number += bytes[i] << (i * 8)

	return number


static func bury_byte_in_bytes(bytes: Array, offset: int, bit_layer: int, data_byte: int):
	"""
	Alter a chunk of 8 bytes in a byte array in order to bury a byte (8 bits, one per chunk byte).
	See test file for examples.

	bytes:
		An array of bytes that will be altered.
	offset:
		The position in the byte array from where to alter the chunk.
	bit_layer:
		The position of the bit to update in each chunk byte.
	data_byte:
		The data byte to burry in the chunk.
	"""
	assert(bytes.size() >= 8, "an array of at least 8 bytes is required")
	var max_offset = int(floor(len(bytes) / 8.0))
	assert(offset >= 0 and offset < max_offset, "offset must be in range [0, %d]" % max_offset)
	assert(bit_layer >= 0 and bit_layer < 8, "bit layer must be in range [0, 7]")
	assert(data_byte >= 0 and data_byte < 1<<8, "data must be a byte")

	# the party begins here, please restart your brain in binary mode to continue
	var layer_mask = (1 << 8) - (1 << bit_layer) - 1
	var bit = 0
	for cursor in 8:
		bit = (data_byte & 1 << (7 - cursor)) >> (7 - cursor)
		bytes[offset * 8 + cursor] = bytes[offset * 8 + cursor] & layer_mask | (bit << bit_layer)


static func extract_byte_from_bytes(bytes: Array, offset: int, bit_layer: int) -> int:
	"""
	Extract a byte buried in a chunk of 8 bytes in a byte array.

	bytes:
		A byte array from which to extrat a byte.
	offset:
		The position in the byte array from where to read the chunk.
	bit_layer:
		The position of the bit to read in each chunk byte.

	return:
		The data byte buried in the chunk.
	"""

	assert(bytes.size() >= 8, "an array of at least 8 bytes is required")
	assert(bit_layer >= 0 and bit_layer < 8, "bit layer must be in range [0, 7] but is %d" % bit_layer)

	var data_byte = 0
	var bit = 0
	for cursor in 8:
		bit = (bytes[offset * 8 + cursor] & ( 1 << bit_layer )) >> bit_layer
		data_byte += bit << (7 - cursor)

	assert(data_byte >= 0 and data_byte < 1 << 8, "extracted data was supposed to be a byte")
	return data_byte


static func compress_string_in_image(input_string: String, image : Image) -> Image:
	"""
	s:
		A utf-8 string containing data to compress (typically in json).
	imgage:
		The image on which data must be writen.

	Returns an image visually similar to the input image and with the same size,
	but with the compressed string `s` encoded inside using steganography.
	"""

	var input_bytes = input_string.to_utf8()
	var payload = Array(input_bytes.compress(File.COMPRESSION_GZIP))

	var header = Array("LisU".to_ascii())
	header.append_array(uint32_to_bytes(payload.size()))     # max file size: 4gb
	header.append_array(uint32_to_bytes(OS.get_unix_time())) # max creation date: 2106/02/07
	assert(header.size() == img_header_size)

	var data_bytes = header.duplicate()
	data_bytes.append_array(payload)

	var image_bytes = Array(image.get_data())
	var layer_capacity = int(floor((image_bytes.size() - img_header_size) / 8))

	assert(payload.size() < layer_capacity * img_nb_layers_max, "too much data to encode")

	var bit_layer = 0
	for cursor in data_bytes.size():
		bit_layer = int(floor(cursor / layer_capacity))
		bury_byte_in_bytes(image_bytes, cursor % layer_capacity, bit_layer, data_bytes[cursor])

	var encoded_image = Image.new()
	encoded_image.create_from_data(image.get_width(), image.get_height(), false,
		Image.FORMAT_RGB8, image_bytes)

	return encoded_image


static func extract_chunk4_from_bytes(bytes: Array, offset: int, bit_layer: int) -> Array:
	var chunk4 = [0, 0, 0, 0]
	for i in 4:
		chunk4[i] = extract_byte_from_bytes(bytes, offset + i, bit_layer)

	return chunk4


static func decompress_string_in_image(image : Image) -> Array: # string level, export date, error
	var image_bytes = image.get_data()
	var layer_capacity = floor((image_bytes.size() - img_header_size) / 8)

	# read header
	var identifier = PoolByteArray(extract_chunk4_from_bytes(image_bytes, 0, 0)).get_string_from_ascii()
#	assert(identifier == "LisU", "bad identifier: '%s' != '%s'" % [identifier , "LisU"])
	if identifier != "LisU":
		printerr("Wrong image header. Are you sure the image has been generated by LAEC is YOU?")
		return [ "", 0, ERR_FILE_UNRECOGNIZED ]

	var payload_size = bytes_to_uint32(extract_chunk4_from_bytes(image_bytes, 4, 0))
	if payload_size > layer_capacity * 7:
		printerr("Inconsistent payload size in image header (%d bytes)." % payload_size)
		return [ "", 0, ERR_INVALID_DATA ]

	var timestamp = bytes_to_uint32(extract_chunk4_from_bytes(image_bytes, 8, 0))

	# read payload
	var payload = Array()
	for cursor in payload_size:
		var bit_layer = int(floor(cursor / layer_capacity))
		payload.append(extract_byte_from_bytes(image_bytes, img_header_size + cursor, bit_layer))

	var decompressed_bytes = PoolByteArray(payload).decompress(1 << 21, File.COMPRESSION_GZIP)
	if decompressed_bytes.size() == 0:
		printerr("Can not decompressed data from image.")
		return [ "", 0, ERR_FILE_CORRUPT ]

	return [ decompressed_bytes.get_string_from_utf8(), timestamp, OK ]


static func get_resource_as_string(r: Resource) -> String:
	var s: String = ""
	# Since I could not find an API to export the Resource to String,
	# we're exporting to a temporary file and then reading from it. -_-
	# This is definitely not thread-safe, and very painful to look at.
	var tmp_filepath := "user://tmp_resource_stup_crou_wesh.tres"
	var save_err: int = ResourceSaver.save(tmp_filepath, r)
	if save_err:
		printerr("Cannot write to `%s`. (Error %d)" % [tmp_filepath, save_err])
		return s
	
	var file := File.new()
	var open_err: int = file.open(tmp_filepath, File.READ)
	if open_err:
		printerr("Cannot open `%s`. (Error %d)" % [tmp_filepath, open_err])
		breakpoint
		return s
	
	s = file.get_as_text()
	file.close()
	
	var dir := Directory.new()
	var removal_err := dir.remove(tmp_filepath)
	if removal_err:
		printerr("Cannot remove directory `%s`. (Error %d)" % [tmp_filepath, removal_err])
		breakpoint
	
	return s
