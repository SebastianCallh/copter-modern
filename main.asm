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
PRG_CNT
START	MV COLL COL_I  "setting up interupt vectors"
	MV TERR TER_I
	MV COLL RES_I  "set to the same as collision as they should do the same thing"
GAME_S	MV 150 P_X     "setup gamestart"
	MV 200 P_Y
	MV 15 HEIGHT
	MV 30 GAP
	MV 1 P_DY
	MV 0 P_CNT
	MV 500 SPD
	UPD
	EINT           "enable interrupts"
GAME_L	CMP 1 P_UPD    "check if player pos should update"
	BEQ UP_OR_D    "if yes, jump to up_or_d"
	PCMP 10        "check if progress reached 10"
	BEQ INC_SPD    "if so, increase speed"
	JMP GAME_L     "else, back to gameloop"
INC_SPD	LPRG 0
	ADD 1 PRG_CNT
	CMP 300 SPD    "check current speed"
	BN DEC_GAP     "if negative, decrease gap"
	SUB 10 SPD     "else increase speed"
DEC_GAP	CMP 10 PRG_CNT "check progress counter"
	BNE GAME_L     "if not equal, return to gameloop"
	MV 0 PRG_CNT   "else reset progress counter"
	CMP 16 GAP     "compare gap to 16"
	BN GAME_L      "if smaller (than 15) return to gameloop"
	SUB 1 GAP      "else decrease gap by 1"
	JMP GAME_L     "return to gameloop"
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
	BEQ MV_DOWN
	SUB 1 HEIGHT
	UPD
	RFI
	JMP GAME_L
DECR	MV &HEIGHT T_HEIGHT
	ADD &GAP T_HEIGHT
	CMP 58 T_HEIGHT
	BP MV_UP
	ADD 1 HEIGHT
	UPD
	RFI
	JMP GAME_L
TERR	RAN RAND1     "save random number to rand"
	AND 3 RAND1   "get two least significant bits of rand"
	ADD &T_PREF RAND1
	CMP 2 RAND1   "compare rand1 with 0"
	BN INCR       "if rand1 < 2, increase terrain height"
	CMP 3 RAND1   "compare rand1 with 3"
	BP DECR       "if rand > 2, decrease terrain height"
	JMP RETURN    "else return to gameloop without terrain change"
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
	MV 500 SPD
	UPD
	RFI
	JMP GAME_L
RESET	MV 1 RUNNING
	MV 200 P_Y
RETURN	RFI
MV_DOWN	MV 1 T_PREF   "make it more likely that the terrain will generate downwards"
	RFI           "return from interrupt"
MV_UP	MV 0 T_PREF   "make it more likely that the terrain will generate upwards"
	RFI           "return from interrupt"
	JMP GAME_L
END	DIE           "else die"