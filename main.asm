COL_I
TER_I
RES_I
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
PRG
P_CNT
SPD
T_PREF
START	MV COLL COL_I  "Setting up interupts"
	MV TERR TER_I
	MV RESET RES_I
	EINT           "enable interrupts"
	MV 150 P_X     "setup gamestart"
	MV 200 P_Y
	MV 15 HEIGHT
	MV 30 GAP
	MV 1 P_DY
	MV 0 P_CNT
	MV 500 SPD
	UPD
GAME_L	CMP 1 P_UPD    "check if player pos should update"
	BEQ UP_OR_D     "if yes, jump to up_or_d"
	PCMP 10
	BEQ GAP_DE
	JMP GAME_L     "else, back to gameloop"
GAP_DE	LPRG 0
	CMP 1 GAP
	BN GAME_L
	SUB 1 GAP
	JMP GAME_L
UP_OR_D	MV 0 P_UPD
	CMP 0 PRESS
	BEQ P_DOWN
	CMP 0 RELEASE
	BEQ P_UP
	MV 0 PRESS
	MV 0 RELEASE
	JMP GAME_L
P_DOWN	CMP 450 P_Y    "check if player can be moved down"
	BP GAME_L      "if not, jump back to gameloop"
	CMP 5 P_CNT
	BNE UPD_P
	MV 0 P_CNT
	CMP 3 P_DY
	BEQ UPD_P
	ADD 1 P_DY
	JMP UPD_P
P_UP	CMP 3 P_Y
	BN GAME_L
	CMP 5 P_CNT
	BNE UPD_P
	MV 0 P_CNT
	CMP -3 P_DY
	BEQ UPD_P
	SUB 1 P_DY
	JMP UPD_P
UPD_P	ADD 1 P_CNT
	ADD &P_DY P_Y
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
	MV 0 HEIGHT
	MV 65 GAP
	UPD
	MV 65535 RAND1
COMP	CMP 0 RAND1
	BEQ RET
	SUB 1 RAND1
	JMP COMP
RET	MV 30 GAP
	MV 15 HEIGHT
	MV 20 P_Y
	UPD
	RFI
	JMP GAME_L
RESET	MV 1 RUNNING
	MV 200 P_Y
RETURN	RFI
	JMP GAME_L
END	DIE           "else die"