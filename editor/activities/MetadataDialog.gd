extends ConfirmationDialog

onready var title := $Layout/TitleRow/Field
onready var congratulation := $Layout/CongratulationRow/Field
onready var authors := $Layout/AuthorsRow/Field
onready var version := $Layout/VersionRow/Field

func pickle() -> Dictionary:
	return {
		'title': self.title.text,
		'congratulation': self.congratulation.text,
		'authors': self.authors.text,
		'version': self.version.text,
	}

func unpickle(pickle: Dictionary):
	self.title.text = pickle.get('title', '')
	self.congratulation.text = pickle.get('congratulation', '')
	self.authors.text = pickle.get('authors', '')
	self.version.text = pickle.get('version', '1')
