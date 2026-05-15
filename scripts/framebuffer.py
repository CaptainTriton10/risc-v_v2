def read_file(filename):
    f = open(filename, "r").readlines()
    fb = ""

    for line in f:
        fb += line.strip() + f"{0:c}{0:c}" * (80 - len(line.strip()))

    return fb

def convert_ascii(raw):
    hex = ""
    for char in raw:
        hex += f"{ord(char):x}"

    # https://stackoverflow.com/a/9475354
    fb = [hex[i:i+8] for i in range(0, len(hex), 8)]
    return fb

raw = read_file("fb.txt")
fb = convert_ascii(raw)

with open("fb.hex", "w") as out:
    out.write("\n".join(fb))