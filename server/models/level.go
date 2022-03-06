package models

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"strings"
	"unicode/utf8"
)


type Level struct {
	// Would love an Uuid as well
	Id             uint   `json:"id" gorm:"primary_key"`
	// Raw JSON of the level pickle
	Json           string `json:"json"`
	// Metadata extracted from the pickle
	Title          string `json:"title"`
	Congratulation string `json:"congratulation"`
	Authors        string `json:"authors"`

}

func (level *Level) LoadFromJson(userlandJson string) error {

	jsonErr := json.Unmarshal([]byte(userlandJson), level)
	if jsonErr != nil {
		return jsonErr
	}

	return nil
}

// Trying to read PHIU directly ////////////////////////////////////////////////////////////////////////////////////////
// This was not a success.  See the test suite.
// I think the byte slice is ok, but it can't find gzip header, nor zlib

// CharactersPretty Ξ#§Ӝ!&¡¤UՖµ¿϶աբգդեզըթժիլխծկձճմյφչպջռվտրӡնքֆշΓΔΘΛ%ΠΣΥΦΧΨΩΫάέήΰαβδεζηθλμνξοπρςστυ<χψωϋύϏϐϑϒϓϔϕϖϗϘϙϚϛϜϝϞϟϠϡϢϣϤϥϦϧϨϩϪϫϬϭϮϯϰϱϲϳϴϵ$123456789abcde=fghijklmnopqrstuvwxyzԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕ@ABCDEFGHIJKLMNOPQRSTV⋅WXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß
const CharactersPretty =
	"Ξ" +
	"#§Ӝ!&¡¤UՖµ¿" +
	"϶աբգդեզըթժիլխծկձճմյφչպջռվտրӡնքֆշ" +
	"ΓΔΘΛ%ΠΣΥΦΧΨΩΫάέήΰαβδεζηθλμνξοπρςστυ<χψωϋύϏϐϑϒϓϔϕϖϗϘϙϚϛϜϝϞϟϠϡϢϣϤϥϦϧϨϩϪϫϬϭϮϯϰϱϲϳϴϵ" +
	"$123456789abcde=fghijklmnopqrstuvwxyz" +
	"ԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕ" +
	"@ABCDEFGHIJKLMNOPQRSTV⋅WXYZ" +
	"ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß"


func getPositionInAlphabet(character string, alphabet string) int {
	pos := strings.Index(alphabet, character)
	if pos == -1 {
		return pos
	}
	return utf8.RuneCountInString(alphabet[:pos])
}


func (level *Level) LoadFromPhiu(phiu string) {

	fmt.Println("len(CharactersPretty)", len(CharactersPretty), CharactersPretty) // 444
	alphabetLen := 0
	for i, _ := range CharactersPretty {
		alphabetLen = i
	}
	fmt.Println("len(CharactersPretty)", alphabetLen) // 442
	fmt.Println("utf8.RuneCountInString(CharactersPretty)", utf8.RuneCountInString(CharactersPretty))

	rawBytes := make([]byte, 16384)
	//rawBytes := []byte(phiu)
	for _, char := range phiu {
		//j := strings.Index(CharactersPretty, string(char))
		j := getPositionInAlphabet(string(char), CharactersPretty)

		//fmt.Println(char, string(char), j, byte(j))
		rawBytes = append(rawBytes, byte(j))
	}

	//fmt.Println("Raw BYTES")
	//fmt.Println(string(rawBytes))

	//rdata := strings.NewReader(string(rawBytes))
	rdata := bytes.NewReader(rawBytes)

	//rz, errz := zlib.NewReader(rdata)
	//if errz != nil {
	//	log.Fatal(errz)
	//}
	//io.Copy(os.Stdout, rz)

	//sz, _ := ioutil.ReadAll(rz)
	//fmt.Println("GZ", sz)
	//rz.Close()

	r, err := gzip.NewReader(rdata)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Reader", r)
	s, _ := ioutil.ReadAll(r)
	fmt.Println("GZ", s)
	//gr := gzip.Reader{}
	//read, errReading := gr.Read(rawBytes)
	//if errReading != nil {
	//	return
	//}
	//fmt.Println(read)
}

