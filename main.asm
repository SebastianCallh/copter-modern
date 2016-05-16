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
PRESS
RELEASE
START	MV 1 RUNNING    "starting sequence"
	MV 150 P_X
	MV 200 P_Y
	MV 15 HEIGHT
	MV 30 GAP
	MV 1 P_DY
GAME_L	CMP 1 P_UPD    "check if player pos should update"
	BEQ UP_OR_D     "if yes, jump to up_or_d"
	JMP GAME_L     "else, back to gameloop"
UP_OR_D	MV 0 P_UPD
	CMP 0 PRESS
	BEQ P_UP
	CMP 0 RELEASE
	BEQ P_DOWN
	MV 0 PRESS
	MV 0 RELEASE
	JMP GAME_L
P_DOWN	CMP 450 P_Y    "check if player can be moved down"
	BP GAME_L      "if not, jump back to gameloop"
	ADD &P_DY P_Y  "else add the value on P_DY to P_Y"
	MV 0 P_UPD     "reset player update"
	UPD
	JMP GAME_L     "jump back to gameloop"
P_UP	CMP 3 P_Y
	BN GAME_L
	SUB &P_DY P_Y
	MV 0 P_UPD
	UPD
	JMP GAME_L
INCR	CMP 1 HEIGHT
	BEQ RETURN
	SUB 1 HEIGHT
	UPD
	RFI
	JMP GAME_L
DECR	MV &HEIGHT T_HEIGHT
	ADD &GAP T_HEIGHT
	CMP 58 T_HEIGHT
	BEQ RETURN
	ADD 1 HEIGHT
	UPD
	RFI
	JMP GAME_L
TERR	RAN RAND1     "save random number to rand"
	AND 3 RAND1   "get two least significant bits of rand"
	CMP 0 RAND1   "compare rand with 0"
	BEQ INCR     "if rand = 0, increase terrain height"
	CMP 1 RAND1   "compare rand with 1"
	BEQ DECR     "if rand = 1, decrease terrain height"
	JMP RETURN   "if rand /= 0 and rand /= 1 then continue gameloop without terrain change"
	MV 1 RUNNING  "set the running flag to 1"
	MV 200 P_X    "set player x"
	MV 300 P_Y    "set player y"
	MV 1 P_DY     "set player dy"
	ADD 6 P_X
COLL	MV 1 RUNNING
	RFI
	JMP GAME_L
RESET	MV 1 RUNNING
	MV 200 P_Y
RETURN	RFI
	JMP GAME_L
END	DIE           "else die"