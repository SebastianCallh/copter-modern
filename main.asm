RUNNING
P_X
P_Y
P_DY
START	MV 1 RUNNING  "set the running flag to 1"
	MV 200 P_X    "set player y"
	MV 300 P_Y    "set player x"
	MV 1 P_DY     "set player dy"
LOOP	ADD &P_DY P_Y "add player dy to player y"
	BEQ LOOP      "if the running flag is still 1 continue game loop" 
END	DIE           "else die"