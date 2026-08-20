from PIL import Image
import numpy as np
from pyConway import Grid, PyConway
from pathlib import Path

# Voornamelijk geschreven door Sieben, hulp van Claude en Gemini voor syntax met png's
# Verifiëert of de door vga gegeneerde png's voldoen aan de regels van Conway's game of life
# moet opgeroepen worden in een andere file (test.py)
# run door eerst 'cd test' en dan 'python verify_PNGs.py'


# kijkt of the png een bepaalde kleur bevat
# kleur meegeven als tuple (R, G, B)
def includes_color(png_path, color):
    with Image.open(png_path) as png:

        color_counts = png.getcolors() # returns array van (count, color)

        colors = [t[1] for t in color_counts]

        return (color in colors)


def png_to_grid(png_path, ROWS, COLS):
    with Image.open(png_path) as png:
        arr = np.array(png)

    height = 480
    width = 640
    cell_height = height // ROWS
    cell_width = width // COLS


    g = Grid(ROWS, COLS) # geïnitialiseerd op allemaal nullen

    for x in range(0, height, cell_height):
        for y in range(0, width, cell_width):
            # extract 16x16 block slice
            block = arr[x : x + cell_height, y : y + cell_width]

            # check if all pixels in the block equal the top-left pixel
            if not np.all(block == block[0, 0]):
                print(f"WARNING: vierkant lijkt niet-uniform op rij {int(x/cell_height)}, kolom {int(y/cell_width)}")
                #raise ValueError(f"{png_path}: niet-uniform vierkant op rij {int(x/square_size)}, kolom {int(y/square_size)} (bekijk zelf de png)")

            if np.array_equal(block[0, 0], (255, 255, 255)): # wit
                g.set(int(x/cell_height), int(y/cell_width), 1)
            elif not np.array_equal(block[0, 0], (0, 0, 0)): # zwart
                raise ValueError(f"{png_path}: bevat andere kleuren dan wit of zwart op rij {int(x/cell_height)}, kolom {int(y/cell_width)} (bekijk zelf de png)")

    return g


def verify_PNGs(folder_path, mode, ROWS, COLS):
    folder_path = Path(folder_path)
    sim_starting = True
    frame_count = 1

    pngs = sorted(folder_path.glob('vga_screen_capture_*.png'))

    if len(pngs) == 0:
        raise AssertionError("geen PNG's gevonden")

    for png in pngs:
        print(png.name)

        if(sim_starting):
            if not includes_color(png, (0, 0, 255)): # frames met blauw hebben een cursos
                sim_starting = False

                grid = png_to_grid(png, ROWS, COLS)
                conway = PyConway(grid, mode)

        else:
            print(f"frame {frame_count}")
            frame_count += 1

            conway.advance()

            current_grid = png_to_grid(png, ROWS, COLS)

            if not current_grid.equal(conway.get_grid()):
                print("gekregen grid")
                current_grid.print()
                print("verwacht grid")
                conway.get_grid().print()
                print("deze test neemt aan dat de simulatie elke frame geüpdate wordt")
                raise AssertionError(f"{png}: resultaat is algoritmisch fout (bekijk zelf de png)")

    print("Algoritmische verificatie van png's complete!")


# danku Claude
if __name__ == "__main__":
    verify_PNGs("output", 0, 12, 16)