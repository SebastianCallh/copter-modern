import sys

#Splits labels from instructions on tabs, so the code must be indented using tabs
#Splits instruction from args using spaces, so they must be separated using spaces
#Comments can be made by separating them fro mteh code via one or several spaces
#Only deals in hexadecimal numbers
#Can only jump backwards using labels

# MV 10    -- Save the number 10 to PMEM(RES)
# MV &10   -- Save the number on memory location 10 to PMEM(RES)
# MV *10   -- Save the number that the address on memory location 10 points to to PMEM(RES)

#Valid code could be:
#START 	JMP 01      #comment
#	MV 12 *10
#END	DIE


def to_hex(n, s):
    return ('{0:0' + str(s) + 'x}').format(int(hex(int(n, 2)), 16))

def to_bin(n, s):
    return format(int(n), '0' + str(s) + 'b')

def make_instr(i):
    return 'x\"' + str(i) + '",\n'

FETCH_NEXT = '100000'
DONT_FETCH_NEXT = '00'
NO_ARGS = '0000'
EMPTY_INSTR = '00000000'

if not len(sys.argv) is 2:
    sys.exit('No code to assemble supplied')
    
op_code = {
    'MV'  : '01',
    'ADD' : '02',
    'SUB' : '03',
    'BEQ' : '04',
    'BNE' : '05',
    'BN'  : '06',
    'JMP' : '07',
    'RES' : '08',
    'DIE' : 'FF'
    }
has_one_arg = ['BEQ', 'BNE', 'BN', 'JMP', 'RES']
has_two_args = ['MV', 'ADD', 'SUB']

lines = []
with open(sys.argv[1]) as f:
    lines = f.readlines()

line_nr = 0;
label_lookup = {}
instructions = ''

for line in lines:
    split_string = line.split('\t')
    label = split_string[0]
    
    
    #Save all labels' line number for jumps
    if label:
        label_lookup[label.replace('\n', '')] = str(line_nr)

    if len(split_string) == 1:
        instructions += make_instr(EMPTY_INSTR)
        continue

    op_and_args = split_string[1].split()
    op = op_and_args[0]
    machine_instr = ''

    if op and op not in op_code:
        sys.exit('Unknown op-code \'{0}\' at line {1}'.format(op, line_nr))

    #Don't create any mods if there are no args
    if len(split_string) >= 2:
        args = op_and_args[1:] 
        mods = ['10' if arg[0] is '*' else 
                '01' if arg[0] is '&' else 
                '00' for arg in args]


    #replace labels with line numbers
    args = [label_lookup[arg] if arg in label_lookup else arg for arg in args]

    #remove prefixes
    args = [arg[1:] if not arg[0].isdigit() else arg for arg in args]
    
    #Construct the final machine code instruction
    if op in has_one_arg or op in has_two_args:
        if op in has_two_args:
            instructions += make_instr(op_code['RES'] + to_hex(mods[1] + FETCH_NEXT + to_bin(args[1], 16), 6))
        instructions += make_instr(op_code[op] + to_hex(mods[0] + FETCH_NEXT + to_bin(args[0], 16), 6))
    else:
        instructions += make_instr(op_code[op] + to_hex('00' + DONT_FETCH_NEXT, 2) + NO_ARGS)

    line_nr += 1

print('Machine code successfully saved to file "machine_code"')
f = open('machine_code','w')
f.write(instructions) 
f.close()
