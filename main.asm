RUNNING
P_X
P_Y
P_DY
HEIGHT
GAP
T_HEIGHT
GAMELOOP
RAND
START	MV 150 P_X
	MV 200 P_Y
	MV 15 HEIGHT
	MV 30 GAP
	MV 1 P_DY
LP	UPD
	JMP LP
INCR	CMP 1 HEIGHT
	BEQ LP
	SUB 1 HEIGHT
	JMP LP
DECR	MV &HEIGHT T_HEIGHT
	ADD &GAP T_HEIGHT
	CMP 58 T_HEIGHT
	BEQ LP
	ADD 1 HEIGHT
	JMP LP
TERR	RAN RAND
	AND 3 RAND
	CMP 0 RAND
	BEQ INCR
	CMP 1 RAND
	BEQ DECR
	JMP LP
	MV 1 RUNNING  "set the running flag to 1"
	MV 200 P_X    "set player x"
	MV 300 P_Y    "set player y"
	MV 1 P_DY     "set player dy"
	ADD 6 P_X
LOOP	ADD &P_DY P_Y "add player dy to player y"
	BEQ LOOP      "if the running flag is still 1 continue game loop" 
END	DIE           "else die"