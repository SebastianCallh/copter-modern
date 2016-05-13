RUNNING
P_X
P_Y
P_DY
HEIGHT
GAP
T_HEIGHT
RAND1
RAND2
P_UPD
INPUT
START	MV 1 RUNNING    "starting sequence"
	MV 150 P_X
	MV 200 P_Y
	MV 15 HEIGHT
	MV 30 GAP
	MV 1 P_DY
GAME_L	CMP 1 P_UPD    "check if player pos should update"
	BEQ GAME_L
	JMP PD
PD	UPD
INCR	CMP 1 HEIGHT
	BEQ GAME_L
	SUB 1 HEIGHT
	UPD
	JMP GAME_L
DECR	MV &HEIGHT T_HEIGHT
	ADD &GAP T_HEIGHT
	CMP 58 T_HEIGHT
	BEQ GAME_L
	ADD 1 HEIGHT
	UPD
	JMP GAME_L
TERR	RAN RAND1     "save random number to rand"
	AND 3 RAND1   "get two least significant bits of rand"
	CMP 0 RAND1   "compare rand with 0"
	BEQ INCR     "if rand = 0, increase terrain height"
	CMP 1 RAND1   "compare rand with 1"
	BEQ DECR     "if rand = 1, decrease terrain height"
	JMP GAME_L   "if rand /= 0 and rand /= 1 then continue gameloop without terrain change"
	MV 1 RUNNING  "set the running flag to 1"
	MV 200 P_X    "set player x"
	MV 300 P_Y    "set player y"
	MV 1 P_DY     "set player dy"
	ADD 6 P_X
LOOP	ADD &P_DY P_Y "add player dy to player y"
	CMP 1 RUNNING
	BEQ LOOP      "if the running flag is still 1 continue game loop" 
END	DIE           "else die"