from pathlib import Path

input_file = "vga/font.hex"
output_file = "font_rows.hex"

out = []

with open(input_file) as f:
    for line in f:
        line = line.strip()

        if not line:
            continue

        char_hex, data = line.split(":")
        char_index = int(char_hex, 16)

        # Split into 16 rows (2 hex chars each)
        rows = [data[i:i+2] for i in range(0, 32, 2)]

        for row_index, row in enumerate(rows):
            addr = char_index * 16 + row_index
            out.append(f"{addr:04x}:{row}")

with open(output_file, "w") as f:
    f.write("\n".join(out))

print("Done.")