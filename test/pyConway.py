"""
Deel Sieben
Deze file simuleert Conway's game of life in python met PyConway en grid-abstractie Grid
Handig om het resultaat van Verilog extern te checken
geïnspireerd de Bart Jacobs-filosofie van objectgericht programmeren
"""

class Grid:

    def __init__(self, rows, cols):
        self.grid = [[0 for _ in range(cols)] for _ in range(rows)]
        self.rows = rows
        self.cols = cols

    def set(self, row, col, value):
        self.grid[row][col] = value

    def get_rows(self):
        return self.rows

    def get_cols(self):
        return self.cols

    def get(self, row, col):
        return self.grid[row][col]

    def equal(self, grid2):
        for row in range(self.rows):
            for col in range(self.cols):
                if self.grid[row][col] != grid2.get(row,col): return False
        return True

    def get_copy(self):
        grid_copy = Grid(self.rows,self.cols)
        for row in range(self.rows):
            for col in range(self.cols):
                grid_copy.set(row,col,self.grid[row][col])
        return grid_copy

    def print(self):
        for row in range(self.rows):
            print(self.grid[row])


class PyConway:

    def __init__(self, grid):
        self.grid = grid
        self.rows = grid.get_rows()
        self.cols = grid.get_cols()
        self.iteration = 0

    def get_grid(self):
        return self.grid.get_copy()

    def __get_neighbours_count(self, central_row, central_col): #__ voor private
        neighbours_count = 0

        for i in range(1,9):
            row = central_row
            col = central_col

            match i:
                case 1:
                    row -= 1
                case 2:
                    row -= 1
                    col += 1
                case 3:
                    col += 1
                case 4:
                    row += 1
                    col += 1
                case 5:
                    row += 1
                case 6:
                    row += 1
                    col -= 1
                case 7:
                    col -= 1
                case 8:
                    row -= 1
                    col -= 1
            if row == -1:
                row = self.rows - 1
            elif row == self.rows:
                row = 0
            if col == -1:
                col = self.cols - 1
            elif col == self.cols:
                col = 0

            if self.grid.get(row,col) == 1:
                neighbours_count += 1

        return neighbours_count

    def advance(self, iterations=1):

        for i in range(iterations):

            self.iteration += 1
            next_grid = Grid(self.rows,self.cols)

            for row in range(self.rows):

                for col in range(self.cols):
                    neighbours_count = self.__get_neighbours_count(row,col)
                    if self.grid.get(row,col) == 1 and (neighbours_count == 3 or neighbours_count == 2):
                        next_grid.set(row, col,1)
                    elif self.grid.get(row,col) == 0 and neighbours_count == 3:
                        next_grid.set(row, col,1)
                    else:
                        next_grid.set(row, col,0)

            self.grid = next_grid
