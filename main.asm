RUNNING
P_X
P_Y
P_DY
START	MV RUNNING 1  "set the running flag to 1"
	MV P_X 200    "set player y"
	MV P_Y 300    "set player x"
	MV P_DY 1     "set player dy"
LOOP	ADD &4 2      "add player dy to player y"
	BEQ LOOP      "if the running flag is still 1 continue game loop" 
END	DIE           "else die"