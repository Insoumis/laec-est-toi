package models

import "testing"

func TestLevel_LoadFromPhiu(t *testing.T) {
	type fields struct {
		Id             uint
		Json           string
		Title          string
		Congratulation string
		Authors        string
	}
	type args struct {
		phiu string
	}
	tests := []struct {
		name   string
		fields fields
		args   args
	}{
		{
			name:   "Basic",
			fields: fields{
				Id:             1,
				Json:           "",
				Title:          "",
				Congratulation: "",
				Authors:        "",
			},
			args:   args{
				phiu: "φ=UΞΞΞΞΞΞӜÍpHhN%դBϙ@ÒϟζρϑυՋbϏϩFϬνÂσψÅτրԾՒՂ=δϰϕԻβΞϩՒեxԴΛAվϣϋξϤηՆςÁεΘkßxՂϡΰδgÃաϯϚ϶լeυΨÔPϢճkψÜtυlUμզeΫդÌ%βՉΠթՈϵΛϰ%ՁϚճIÏÝըՇϙդ¤¿ÂϚζճΓԹB⋅cԷϔԶՁϮpυβϦԹՁՄՆÖϮlϭϣպֆÅϋϳjԴՅυΛθՎÔϰLQωaέ7ճՉϥÍչOÇχËտՅռΓ$FßՖϲF3ԲϕÆ§ϞϕËξϢտԵԲϟϙËfՈÝτFϙµϮϱAREՒԻkQÙΰլϤh9ÚSnϧԷϲ5ËLqÂճοd#ԾϪηϑØϑϮզξϮgϙΓՅըզՋԾs%jQիϤՕ$ÁϪδԿλՒFάΓήϱխaϧԴ5LՄծoϏήաdϏխνϗnνÑLβϪՋΫӡDպÍΞ9ϑϝδԺÑςοΧԺբzկËςπՂΘω51ÈԺ3×3µÏՇβυ3ÄÎϥÒÞΛΠwNψyՍϯջ9բϒΧ=ԿpέϔbaՋϲθÕ7ϜՎՀβΨՍÚÞյԹՃσ1XO&քάՖՖ=ΰձεw#ÊնJրϏϢ@τRϵ6ÕϘ1ÌÄPΩՑՋWiÊ϶ϒwϩδϰÚÉ×ձϖrՔϑԾ=ՔյRΩΩÃ⋅կϵΧՕHµϪՍΦήÁϞsÃήÐάϳՌÛsηÑϚ4վΓdϣϯjՊÁIςՏiՌÛpϬÃՑդՖԵέQլգϋÕν4ջIÈտT1ӡÒe¿¿վÃEզDDθÅըτPϵ3տվ5ԳSÝχεՉϙե7ÁλϨԸÊxձΣRÞեfՓԾաԹfնgԷËÒϮYΔՅՂխÛυoՈըέTέqrÂάչըυuϓΥձϩ3#ϑΰϧlϏզΞΞ",
			},
		},
		// TODO: Add more test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			level := &Level{
				//Id:             tt.fields.Id,
				//Json:           tt.fields.Json,
				//Title:          tt.fields.Title,
				//Congratulation: tt.fields.Congratulation,
				//Authors:        tt.fields.Authors,
			}
			level.LoadFromPhiu(tt.args.phiu)
		})
	}
}
