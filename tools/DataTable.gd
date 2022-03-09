extends GridContainer
class_name DataTable


func add_header(row):
	return add_header_row(row)


func add_header_row(row):
	for element in row:
		var cell = create_header_cell(element)
		add_child(cell)


func add_row(row):
	for element in row:
		var cell = create_cell(element)
		add_child(cell)


func create_header_cell(element):
	var cell = Label.new()
	cell.align = Label.ALIGN_CENTER
	cell.valign = Label.VALIGN_CENTER
	cell.text = str(element)
	return cell


func create_cell(element):
	var cell = Label.new()
	cell.align = Label.ALIGN_CENTER
	cell.valign = Label.VALIGN_CENTER
	cell.text = str(element)
	return cell
