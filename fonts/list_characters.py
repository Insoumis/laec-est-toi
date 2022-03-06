import sys
import regex
from fontTools.ttLib import TTFont

def get_font_characters(font_path):
    with TTFont(font_path) as font:
        characters = {chr(y[0]) for x in font["cmap"].tables for y in x.cmap.items()}
    return characters

if __name__ == "__main__":
    all_chars = get_font_characters(sys.argv[1])
    print("All characters (%d):" % (len(all_chars)))
    #print(all_chars)
    print([[c, not regex.match(r"\P{C}+", c)] for c in all_chars])
    
    most_chars = []
    for c in all_chars:
        # https://en.wikipedia.org/wiki/Unicode_character_property
        
        # No control chars
        if regex.match(r"\p{C}+", c):
            continue
        # No separator chars
        if regex.match(r"\p{Z}+", c):
            continue
        
        if regex.match(r"\p{Ps}|\p{Pe}|\p{Pi}|\p{Pf}", c):
            continue
        
        # Only letters
        #if not regex.match(r"\p{L}+", c):
            #continue
        
        most_chars.append(c)
    
    print("Most characters (%d):" % (len(most_chars)))
    print("".join(most_chars))
